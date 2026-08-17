import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/landmark.dart';
import '../services/landmark_repository.dart';
import '../widgets/landmark_detail_sheet.dart';

enum SortOrder { scoreDesc, scoreAsc }

class LandmarksScreen extends StatefulWidget {
  const LandmarksScreen({super.key});
  @override
  State<LandmarksScreen> createState() => _LandmarksScreenState();
}

class _LandmarksScreenState extends State<LandmarksScreen> {
  final _repo = LandmarkRepository();
  List<Landmark> _all = [];
  bool _loading = true;
  SortOrder _sort = SortOrder.scoreDesc;
  double _minScore = 0;
  double _maxPossible = 100;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _repo.getLandmarks();
    if (!mounted) return;
    final maxScore = data.isEmpty
        ? 100.0
        : data.map((l) => l.score).reduce((a, b) => a > b ? a : b);
    setState(() {
      _all = data;
      _maxPossible = maxScore <= 0 ? 100 : maxScore;
      _loading = false;
    });
  }

  List<Landmark> get _visible {
    final filtered = _all.where((l) => l.score >= _minScore).toList();
    filtered.sort((a, b) => _sort == SortOrder.scoreDesc
        ? b.score.compareTo(a.score)
        : a.score.compareTo(b.score));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      appBar: AppBar(title: const Text('Landmarks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Text('Sort:'),
                const SizedBox(width: 8),
                DropdownButton<SortOrder>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                        value: SortOrder.scoreDesc,
                        child: Text('Score: High to Low')),
                    DropdownMenuItem(
                        value: SortOrder.scoreAsc,
                        child: Text('Score: Low to High')),
                  ],
                  onChanged: (v) => setState(() => _sort = v!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Min score: ${_minScore.toStringAsFixed(0)}'),
                Expanded(
                  child: Slider(
                    value: _minScore,
                    min: 0,
                    max: _maxPossible,
                    divisions: 20,
                    onChanged: (v) => setState(() => _minScore = v),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: list.isEmpty
                        ? ListView(children: const [
                            Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                  child: Text('No landmarks match this filter.')),
                            )
                          ])
                        : ListView.builder(
                            itemCount: list.length,
                            itemBuilder: (context, i) {
                              final l = list[i];
                              final imageUrl = l.image != null
                                  ? '${AppConstants.serverBase}${l.image}'
                                  : null;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: imageUrl != null
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  child: imageUrl == null
                                      ? const Icon(Icons.place)
                                      : null,
                                ),
                                title: Text(l.title),
                                subtitle: Text(
                                    'Score: ${l.score.toStringAsFixed(1)}  •  '
                                    'Visits: ${l.visitCount}'),
                                onTap: () async {
                                  final msg = await showModalBottomSheet<String>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) =>
                                        LandmarkDetailSheet(landmark: l),
                                  );
                                  if (msg != null && mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                            SnackBar(content: Text(msg)));
                                    _load();
                                  }
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}
