import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/visit.dart';
import '../services/landmark_repository.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});
  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _repo = LandmarkRepository();
  List<Visit> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getVisitHistory();
    if (!mounted) return;
    setState(() {
      _visits = data;
      _loading = false;
    });
  }

  Widget _statusChip(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'done':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'failed':
        color = Colors.red;
        icon = Icons.error;
        break;
      case 'queued':
        color = Colors.grey;
        icon = Icons.cloud_off;
        break;
      default: // pending
        color = Colors.orange;
        icon = Icons.hourglass_top;
    }
    return Chip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(status),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _visits.isEmpty
                  ? ListView(children: const [
                      Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('No visits yet.')),
                      )
                    ])
                  : ListView.builder(
                      itemCount: _visits.length,
                      itemBuilder: (context, i) {
                        final v = _visits[i];
                        DateTime time;
                        try {
                          time = DateTime.parse(v.visitTime);
                        } catch (_) {
                          time = DateTime.now();
                        }
                        final formatted =
                            DateFormat('MMM d, yyyy • h:mm a').format(time);
                        return ListTile(
                          leading: const Icon(Icons.flag_circle_outlined),
                          title: Text(v.landmarkTitle),
                          subtitle: Text(
                            v.status == 'done' && v.distance != null
                                ? '$formatted\nDistance: ${v.distance!.toStringAsFixed(1)} m'
                                : formatted,
                          ),
                          isThreeLine: v.status == 'done',
                          trailing: _statusChip(v.status),
                        );
                      },
                    ),
            ),
    );
  }
}
