import 'package:workmanager/workmanager.dart';
import '../constants.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

/// This is the single WorkManager-based mechanism that covers both:
///   - polling get_job_status for pending visit jobs (Requirement 3/10)
///   - draining the offline visit queue once connectivity returns (Req 8/10)
/// It survives app restarts because WorkManager persists its work queue,
/// and it never blocks the UI thread because it runs in a background isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final api = ApiService();
    final db = DatabaseService.instance;

    try {
      switch (task) {
        case AppConstants.pollJobTask:
          await _pollSingleJob(api, db, inputData);
          break;

        case AppConstants.periodicSyncTask:
        default:
          await _drainOfflineQueue(api, db);
          await _pollAllPendingJobs(api, db);
          break;
      }
      return Future.value(true);
    } catch (e) {
      // Returning false tells WorkManager to retry with backoff.
      return Future.value(false);
    }
  });
}

Future<void> _pollSingleJob(
    ApiService api, DatabaseService db, Map<String, dynamic>? input) async {
  if (input == null) return;
  final visitRowId = input['visitRowId'] as int;
  final jobId = input['jobId'] as int;

  final status = await api.getJobStatus(jobId);
  final state = status['status'];

  if (state == 'done') {
    final distance = double.tryParse(status['distance'].toString()) ?? 0.0;
    await db.updateVisit(visitRowId, status: 'done', distance: distance);
  } else if (state == 'failed') {
    await db.updateVisit(visitRowId, status: 'failed');
  } else {
    // still pending -> reschedule another one-off poll a few seconds later
    // instead of blocking this isolate with a sleep loop.
    await Workmanager().registerOneOffTask(
      'poll-$jobId-${DateTime.now().millisecondsSinceEpoch}',
      AppConstants.pollJobTask,
      initialDelay: const Duration(seconds: 8),
      inputData: {'visitRowId': visitRowId, 'jobId': jobId},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}

Future<void> _pollAllPendingJobs(ApiService api, DatabaseService db) async {
  if (!await ConnectivityService.isOnline()) return;
  final pending = await db.getPendingVisits();
  for (final v in pending) {
    if (v.jobId == null || v.id == null) continue;
    try {
      final status = await api.getJobStatus(v.jobId!);
      final state = status['status'];
      if (state == 'done') {
        final d = double.tryParse(status['distance'].toString()) ?? 0.0;
        await db.updateVisit(v.id!, status: 'done', distance: d);
      } else if (state == 'failed') {
        await db.updateVisit(v.id!, status: 'failed');
      }
      // if still pending, the periodic task will simply check again later
    } catch (_) {
      // ignore and retry on next periodic run
    }
  }
}

Future<void> _drainOfflineQueue(ApiService api, DatabaseService db) async {
  if (!await ConnectivityService.isOnline()) return;
  final queued = await db.getQueuedVisits();
  for (final v in queued) {
    if (v.id == null) continue;
    try {
      final jobId = await api.visitLandmark(
        landmarkId: v.landmarkId,
        userLat: v.userLat,
        userLon: v.userLon,
      );
      await db.updateVisit(v.id!, jobId: jobId, status: 'pending');
      // kick off fast polling for this newly-created job
      await Workmanager().registerOneOffTask(
        'poll-$jobId-${DateTime.now().millisecondsSinceEpoch}',
        AppConstants.pollJobTask,
        initialDelay: const Duration(seconds: 5),
        inputData: {'visitRowId': v.id, 'jobId': jobId},
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {
      // leave as 'queued' - retried with backoff on the next periodic run
    }
  }
}

class WorkManagerService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
    // Android enforces a 15-minute minimum interval for real periodic work.
    await Workmanager().registerPeriodicTask(
      'periodic-sync-task',
      AppConstants.periodicSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// Called right after a visit is created (online or once it leaves the
  /// offline queue) to start fast near-real-time polling for that one job.
  static Future<void> scheduleJobPoll(
      {required int visitRowId, required int jobId}) async {
    await Workmanager().registerOneOffTask(
      'poll-$jobId-${DateTime.now().millisecondsSinceEpoch}',
      AppConstants.pollJobTask,
      initialDelay: const Duration(seconds: 5),
      inputData: {'visitRowId': visitRowId, 'jobId': jobId},
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
