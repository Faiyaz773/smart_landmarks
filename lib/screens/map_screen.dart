import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../models/landmark.dart';
import '../services/landmark_repository.dart';
import '../widgets/landmark_detail_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final _repo = LandmarkRepository();
  List<Landmark> _landmarks = [];
  bool _loading = true;

  static const _bangladesh = ll.LatLng(23.6850, 90.3563);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getLandmarks();
    if (!mounted) return;
    setState(() {
      _landmarks = data;
      _loading = false;
    });
  }

  Color _colorForScore(double score) {
    if (_landmarks.isEmpty) return Colors.orange;
    final scores = _landmarks.map((l) => l.score).toList();
    final min = scores.reduce((a, b) => a < b ? a : b);
    final max = scores.reduce((a, b) => a > b ? a : b);
    final t = (max - min).abs() < 0.0001 ? 1.0 : (score - min) / (max - min);
    return Color.lerp(Colors.red, Colors.green, t.clamp(0.0, 1.0))!;
  }

  void _openDetails(Landmark landmark) async {
    final msg = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LandmarkDetailSheet(landmark: landmark),
    );
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Landmarks Map'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              options: const MapOptions(
                initialCenter: _bangladesh,
                initialZoom: 7,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.smart_landmarks',
                ),
                MarkerLayer(
                  markers: _landmarks
                      .map((l) => Marker(
                            point: ll.LatLng(l.lat, l.lon),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () => _openDetails(l),
                              child: Icon(Icons.location_pin,
                                  color: _colorForScore(l.score), size: 40),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
    );
  }
}
