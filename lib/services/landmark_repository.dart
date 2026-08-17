import 'dart:io';
import '../models/landmark.dart';
import '../models/visit.dart';
import 'api_service.dart';
import 'database_service.dart';
import 'connectivity_service.dart';
import 'workmanager_service.dart';

/// UI screens only ever talk to this class. It decides whether to hit the
/// network or fall back to the local SQLite cache, so screens don't need to
/// know about connectivity at all.
class LandmarkRepository {
  final ApiService _api = ApiService();
  final DatabaseService _db = DatabaseService.instance;

  /// Always returns *something* to show (cache first), and refreshes from
  /// the network in the background when possible.
  Future<List<Landmark>> getLandmarks({bool forceRefresh = false}) async {
    final online = await ConnectivityService.isOnline();
    if (online) {
      try {
        final fresh = await _api.getLandmarks();
        await _db.replaceLandmarks(fresh);
        return fresh;
      } catch (_) {
        // network hiccup - fall through to cache
      }
    }
    return _db.getCachedLandmarks();
  }

  Future<List<Landmark>> getCachedLandmarks() => _db.getCachedLandmarks();

  Future<List<Visit>> getVisitHistory() => _db.getAllVisits();

  /// Handles both the online and offline paths for Requirement 3 + 8.
  Future<String> visitLandmark({
    required Landmark landmark,
    required double userLat,
    required double userLon,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final online = await ConnectivityService.isOnline();

    if (!online) {
      await _db.insertVisit(Visit(
        landmarkId: landmark.id,
        landmarkTitle: landmark.title,
        visitTime: nowIso,
        userLat: userLat,
        userLon: userLon,
        status: 'queued',
      ));
      return 'You are offline. Visit queued and will sync automatically.';
    }

    try {
      final jobId = await _api.visitLandmark(
        landmarkId: landmark.id,
        userLat: userLat,
        userLon: userLon,
      );
      final rowId = await _db.insertVisit(Visit(
        landmarkId: landmark.id,
        landmarkTitle: landmark.title,
        visitTime: nowIso,
        userLat: userLat,
        userLon: userLon,
        jobId: jobId,
        status: 'pending',
      ));
      await WorkManagerService.scheduleJobPoll(visitRowId: rowId, jobId: jobId);
      return 'Visit submitted! Tracking distance in the background...';
    } catch (e) {
      // API reachable but call failed for another reason -> still queue it
      // so nothing is silently lost.
      await _db.insertVisit(Visit(
        landmarkId: landmark.id,
        landmarkTitle: landmark.title,
        visitTime: nowIso,
        userLat: userLat,
        userLon: userLon,
        status: 'queued',
      ));
      return 'Could not reach server, visit queued for retry.';
    }
  }

  Future<int> createLandmark({
    required String title,
    required double lat,
    required double lon,
    File? imageFile,
  }) async {
    final id = await _api.createLandmark(
        title: title, lat: lat, lon: lon, imageFile: imageFile);
    // refresh cache so the new landmark shows up immediately
    await getLandmarks();
    return id;
  }

  Future<void> deleteLandmark(int id) async {
    await _api.deleteLandmark(id);
    await getLandmarks();
  }

  Future<void> restoreLandmark(int id) async {
    await _api.restoreLandmark(id);
    await getLandmarks();
  }
}
