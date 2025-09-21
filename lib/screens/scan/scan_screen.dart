import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motives_tneww/screens/scan/scan_result_screen.dart';

import '../../Model/scanjuicemodel.dart';
import '../../Repository/retina_repo.dart';



class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final picker = ImagePicker();
  File? _image;
  bool _busy = false;
  String? _error;

  Future<void> _pick(ImageSource src) async {
    setState(() => _error = null);
    try {
      final x = await picker.pickImage(source: src, imageQuality: 95);
      if (x != null) setState(() => _image = File(x.path));
    } catch (e) {
      setState(() => _error = 'Pick failed: $e');
    }
  }

  Future<void> _upload() async {
    if (_image == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final api = RetinaApiHttp();
      final ScanJuiceResponse res = await api.scanJuiceGlass(_image!);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultPage(result: res)));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final img = _image;
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Juice Glass')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          if (_error != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: Center(
              child: img == null
                  ? const Text('No image selected', style: TextStyle(fontSize: 16))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(img, fit: BoxFit.contain),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.camera),
                icon: const Icon(Icons.photo_camera),
                label: const Text('Camera'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _upload,
              icon: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.cloud_upload),
              label: Text(_busy ? 'Uploading...' : 'Upload & Scan'),
            ),
          ),
        ]),
      ),
    );
  }
}
