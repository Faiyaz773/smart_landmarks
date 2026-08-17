import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/landmark.dart';
import '../services/landmark_repository.dart';
import '../services/location_service.dart';

class LandmarkDetailSheet extends StatefulWidget {
  final Landmark landmark;
  const LandmarkDetailSheet({super.key, required this.landmark});

  @override
  State<LandmarkDetailSheet> createState() => _LandmarkDetailSheetState();
}

class _LandmarkDetailSheetState extends State<LandmarkDetailSheet> {
  final _repo = LandmarkRepository();
  bool _visiting = false;

  Future<void> _visit() async {
    setState(() => _visiting = true);
    try {
      final position = await LocationService.getCurrentLocation();
      final msg = await _repo.visitLandmark(
        landmark: widget.landmark,
        userLat: position.latitude,
        userLon: position.longitude,
      );
      if (mounted) Navigator.pop(context, msg);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _visiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.landmark;
    final imageUrl =
        l.image != null ? '${AppConstants.serverBase}${l.image}' : null;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox(
                      height: 80,
                      child: Center(child: Icon(Icons.broken_image)))),
            ),
          const SizedBox(height: 12),
          Text(l.title,
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Score: ${l.score.toStringAsFixed(1)}   '
              'Visits: ${l.visitCount}   '
              'Avg distance: ${l.avgDistance.toStringAsFixed(1)} m'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _visiting ? null : _visit,
              icon: _visiting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.directions_walk),
              label: Text(_visiting ? 'Submitting...' : 'Visit this landmark'),
            ),
          ),
        ],
      ),
    );
  }
}
