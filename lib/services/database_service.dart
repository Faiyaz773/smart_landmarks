import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/landmark.dart';
import '../models/visit.dart';

class DatabaseService {
  DatabaseService._internal();
  static final DatabaseService instance = DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_landmarks.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE landmarks (
            id INTEGER PRIMARY KEY,
            title TEXT NOT NULL,
            lat REAL NOT NULL,
            lon REAL NOT NULL,
            image TEXT,
            score REAL NOT NULL DEFAULT 0,
            visit_count INTEGER NOT NULL DEFAULT 0,
            avg_distance REAL NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE visits (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            landmark_id INTEGER NOT NULL,
            landmark_title TEXT NOT NULL,
            visit_time TEXT NOT NULL,
            user_lat REAL NOT NULL,
            user_lon REAL NOT NULL,
            job_id INTEGER,
            status TEXT NOT NULL,
            distance REAL
          )
        ''');
      },
    );
  }

  // ---------------- Landmarks (cache) ----------------

  /// Replaces the whole local cache with a fresh list from the server.
  /// Because get_landmarks only returns active rows, anything soft-deleted
  /// on the server simply disappears from the cache too (Requirement 7).
  Future<void> replaceLandmarks(List<Landmark> landmarks) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('landmarks');
      for (final l in landmarks) {
        await txn.insert('landmarks', l.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Landmark>> getCachedLandmarks() async {
    final db = await database;
    final rows = await db.query('landmarks', orderBy: 'score DESC');
    return rows.map((r) => Landmark.fromDb(r)).toList();
  }

  // ---------------- Visits / offline queue ----------------

  Future<int> insertVisit(Visit visit) async {
    final db = await database;
    return db.insert('visits', visit.toDb());
  }

  Future<void> updateVisit(int id,
      {int? jobId, String? status, double? distance}) async {
    final db = await database;
    final values = <String, dynamic>{};
    if (jobId != null) values['job_id'] = jobId;
    if (status != null) values['status'] = status;
    if (distance != null) values['distance'] = distance;
    if (values.isEmpty) return;
    await db.update('visits', values, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Visit>> getAllVisits() async {
    final db = await database;
    final rows = await db.query('visits', orderBy: 'visit_time DESC');
    return rows.map((r) => Visit.fromDb(r)).toList();
  }

  /// Visits still waiting on the server (have a job_id, not resolved yet).
  Future<List<Visit>> getPendingVisits() async {
    final db = await database;
    final rows = await db.query('visits', where: "status = 'pending'");
    return rows.map((r) => Visit.fromDb(r)).toList();
  }

  /// Visits created while offline, never sent to the server yet.
  Future<List<Visit>> getQueuedVisits() async {
    final db = await database;
    final rows = await db.query('visits', where: "status = 'queued'");
    return rows.map((r) => Visit.fromDb(r)).toList();
  }
}
