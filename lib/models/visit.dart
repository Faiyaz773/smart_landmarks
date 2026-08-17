/// Status lifecycle of a visit row:
/// queued  -> created while offline, not yet POSTed to the server
/// pending -> POSTed, we have a job_id, waiting for get_job_status
/// done    -> job finished, distance available
/// failed  -> job or POST failed
class Visit {
  final int? id;
  final int landmarkId;
  final String landmarkTitle;
  final String visitTime; // ISO8601 string
  final double userLat;
  final double userLon;
  final int? jobId;
  final String status;
  final double? distance;

  Visit({
    this.id,
    required this.landmarkId,
    required this.landmarkTitle,
    required this.visitTime,
    required this.userLat,
    required this.userLon,
    this.jobId,
    required this.status,
    this.distance,
  });

  factory Visit.fromDb(Map<String, dynamic> row) {
    return Visit(
      id: row['id'] as int?,
      landmarkId: row['landmark_id'] as int,
      landmarkTitle: row['landmark_title'] as String,
      visitTime: row['visit_time'] as String,
      userLat: row['user_lat'] as double,
      userLon: row['user_lon'] as double,
      jobId: row['job_id'] as int?,
      status: row['status'] as String,
      distance: row['distance'] as double?,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      if (id != null) 'id': id,
      'landmark_id': landmarkId,
      'landmark_title': landmarkTitle,
      'visit_time': visitTime,
      'user_lat': userLat,
      'user_lon': userLon,
      'job_id': jobId,
      'status': status,
      'distance': distance,
    };
  }

  Visit copyWith({int? jobId, String? status, double? distance}) {
    return Visit(
      id: id,
      landmarkId: landmarkId,
      landmarkTitle: landmarkTitle,
      visitTime: visitTime,
      userLat: userLat,
      userLon: userLon,
      jobId: jobId ?? this.jobId,
      status: status ?? this.status,
      distance: distance ?? this.distance,
    );
  }
}
