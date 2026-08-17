import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/landmark.dart';
import '../services/landmark_repository.dart';
import '../services/location_service.dart';

class AddViewScreen extends StatefulWidget {
  const AddViewScreen({super.key});
  @override
  State<AddViewScreen> createState() => _AddViewScreenState();
}

class _AddViewScreenState extends State<AddViewScreen> {
  final _repo = LandmarkRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lonCtrl = TextEditingController();
  File? _image;
  bool _submitting = false;
  bool _fetchingLocation = false;

  List<Landmark> _landmarks = [];
  bool _loadingList = true;

  @override
  void initState() {
    super.initState();
    _loadList();
  }

  Future<void> _loadList() async {
    setState(() => _loadingList = true);
    final data = await _repo.getLandmarks();
    if (!mounted) return;
    setState(() {
      _landmarks = data;
      _loadingList = false;
    });
  }

  Future<void> _autoFillLocation() async {
    setState(() => _fetchingLocation = true);
    try {
      final pos = await LocationService.getCurrentLocation();
      _latCtrl.text = pos.latitude.toStringAsFixed(6);
      _lonCtrl.text = pos.longitude.toStringAsFixed(6);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _repo.createLandmark(
        title: _titleCtrl.text.trim(),
        lat: double.parse(_latCtrl.text.trim()),
        lon: double.parse(_lonCtrl.text.trim()),
        imageFile: _image,
      );
      _titleCtrl.clear();
      _latCtrl.clear();
      _lonCtrl.clear();
      setState(() => _image = null);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Landmark created!')));
      }
      _loadList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(Landmark l) async {
    try {
      await _repo.deleteLandmark(l.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('"${l.title}" deleted (soft delete)')));
      }
      _loadList();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add / View Landmarks')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Add a new landmark',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Title', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _latCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                        decoration: const InputDecoration(
                            labelText: 'Latitude',
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lonCtrl,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true),
                        decoration: const InputDecoration(
                            labelText: 'Longitude',
                            border: OutlineInputBorder()),
                        validator: (v) =>
                            (v == null || double.tryParse(v) == null)
                                ? 'Invalid'
                                : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _fetchingLocation ? null : _autoFillLocation,
                  icon: _fetchingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Use current GPS location'),
                ),
                const SizedBox(height: 12),
                if (_image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(_image!, height: 140, fit: BoxFit.cover),
                  ),
                OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: Text(_image == null ? 'Pick image' : 'Change image'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Create Landmark'),
                ),
              ],
            ),
          ),
          const Divider(height: 40),
          Text('Manage landmarks',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_loadingList)
            const Center(child: CircularProgressIndicator())
          else if (_landmarks.isEmpty)
            const Text('No landmarks yet.')
          else
            ..._landmarks.map((l) => ListTile(
                  title: Text(l.title),
                  subtitle: Text('Score: ${l.score.toStringAsFixed(1)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(l),
                  ),
                )),
        ],
      ),
    );
  }
}
