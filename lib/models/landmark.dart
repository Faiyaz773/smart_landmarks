class Landmark {
  final int id;
  final String title;
  final double lat;
  final double lon;
  final String? image; // relative path from API, nullable
  final double score;
  final int visitCount;
  final double avgDistance;

  Landmark({
    required this.id,
    required this.title,
    required this.lat,
    required this.lon,
    required this.image,
    required this.score,
    required this.visitCount,
    required this.avgDistance,
  });

  factory Landmark.fromApi(Map<String, dynamic> json) {
    return Landmark(
      id: int.parse(json['id'].toString()),
      title: json['title']?.toString() ?? 'Untitled',
      lat: double.tryParse(json['lat'].toString()) ?? 0.0,
      lon: double.tryParse(json['lon'].toString()) ?? 0.0,
      image: json['image']?.toString(),
      score: double.tryParse(json['score'].toString()) ?? 0.0,
      visitCount: int.tryParse(json['visit_count'].toString()) ?? 0,
      avgDistance: double.tryParse(json['avg_distance'].toString()) ?? 0.0,
    );
  }

  factory Landmark.fromDb(Map<String, dynamic> row) {
    return Landmark(
      id: row['id'] as int,
      title: row['title'] as String,
      lat: row['lat'] as double,
      lon: row['lon'] as double,
      image: row['image'] as String?,
      score: row['score'] as double,
      visitCount: row['visit_count'] as int,
      avgDistance: row['avg_distance'] as double,
    );
  }

  Map<String, dynamic> toDb() {
    return {
      'id': id,
      'title': title,
      'lat': lat,
      'lon': lon,
      'image': image,
      'score': score,
      'visit_count': visitCount,
      'avg_distance': avgDistance,
    };
  }
}
