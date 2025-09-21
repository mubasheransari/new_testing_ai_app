import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:motives_tneww/screens/scan/scan_result_screen.dart';

import '../../Model/scanjuicemodel.dart';
import '../../Repository/retina_repo.dart';

class NewScanScreen extends StatefulWidget {
  const NewScanScreen({super.key});

  @override
  State<NewScanScreen> createState() => _NewScanScreenState();
}

class _NewScanScreenState extends State<NewScanScreen> {
  static const accent = Color(0xFFE97C42);

  final picker = ImagePicker();
  File? _image;
  bool _busy = false;
  String? _error;

  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Colors.transparent),
  );

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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScanResultScreen(result: res)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const fill = Color(0xFFF4F5F7);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header title + orange underline
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scan'.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const SizedBox(
                    width: 57,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.all(Radius.circular(2)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Welcome row + shapes (match login)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Juice Image Scan!',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700)),
                        SizedBox(height: 6),
                        Text('Upload a juice image to scan!',
                            style:
                                TextStyle(fontSize: 14, color: Colors.black54)),
                      ],
                    ),
                  ),
                  const _DecorShapes(),
                ],
              ),

              const SizedBox(height: 28),

              // Label
              const Text('Image',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              // Preview box styled like filled textfields
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: _image == null
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo,
                              size: 48, color: Colors.black45),
                          const SizedBox(height: 8),
                          Text('No image selected',
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(_image!,
                            fit: BoxFit.cover, width: double.infinity),
                      ),
              ),

              const SizedBox(height: 14),

              if (_error != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                ),

              // Pick buttons (match vibe)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: fill,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        backgroundColor: fill,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        side: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // Upload button — same style as login FilledButton
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _upload,
                  child: _busy
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : const Text('Scan',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same decorative shapes from your NewLoginScreen
class _DecorShapes extends StatelessWidget {
  const _DecorShapes();

  @override
  Widget build(BuildContext context) {
    const light = Color(0xFFFFE1D2);
    const mid = Color(0xFFF6B79C);
    const dark = Color(0xFFE97C42);

    Widget block(Color c, {double w = 84, double h = 26, double angle = .6}) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: w,
          height: h,
          decoration:
              BoxDecoration(color: c, borderRadius: BorderRadius.circular(6)),
        ),
      );
    }

    return const SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -6, top: 0, child: _Block(color: light)),
          Positioned(right: 6, top: 22, child: _Block(color: mid, w: 78)),
          Positioned(
              right: -12, top: 48, child: _Block(color: dark, w: 64, h: 22)),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final Color color;
  final double w, h, angle;
  const _Block(
      {required this.color, this.w = 84, this.h = 26, this.angle = .6});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: w,
        height: h,
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      ),
    );
  }
}




// class ScanPage extends StatefulWidget {
//   const ScanPage({super.key});
//   @override
//   State<ScanPage> createState() => _ScanPageState();
// }

// class _ScanPageState extends State<ScanPage> {
//   final picker = ImagePicker();
//   File? _image;
//   bool _busy = false;
//   String? _error;

//   Future<void> _pick(ImageSource src) async {
//     setState(() => _error = null);
//     try {
//       final x = await picker.pickImage(source: src, imageQuality: 95);
//       if (x != null) setState(() => _image = File(x.path));
//     } catch (e) {
//       setState(() => _error = 'Pick failed: $e');
//     }
//   }

//   Future<void> _upload() async {
//     if (_image == null) {
//       setState(() => _error = 'Please select an image first.');
//       return;
//     }
//     setState(() {
//       _busy = true;
//       _error = null;
//     });

//     try {
//       final api = RetinaApiHttp();
//       final ScanJuiceResponse res = await api.scanJuiceGlass(_image!);
//       if (!mounted) return;
//       Navigator.of(context).push(MaterialPageRoute(builder: (_) => ResultPage(result: res)));
//     } catch (e) {
//       setState(() => _error = e.toString());
//     } finally {
//       if (mounted) setState(() => _busy = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final img = _image;
//     return Scaffold(
//       appBar: AppBar(title: const Text('Scan Juice Glass')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(children: [
//           if (_error != null)
//             Container(
//               width: double.infinity,
//               margin: const EdgeInsets.only(bottom: 12),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Text(_error!, style: const TextStyle(color: Colors.red)),
//             ),
//           Expanded(
//             child: Center(
//               child: img == null
//                   ? const Text('No image selected', style: TextStyle(fontSize: 16))
//                   : ClipRRect(
//                       borderRadius: BorderRadius.circular(12),
//                       child: Image.file(img, fit: BoxFit.contain),
//                     ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _busy ? null : () => _pick(ImageSource.gallery),
//                 icon: const Icon(Icons.photo_library),
//                 label: const Text('Gallery'),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _busy ? null : () => _pick(ImageSource.camera),
//                 icon: const Icon(Icons.photo_camera),
//                 label: const Text('Camera'),
//               ),
//             ),
//           ]),
//           const SizedBox(height: 12),
//           SizedBox(
//             width: double.infinity,
//             child: ElevatedButton.icon(
//               onPressed: _busy ? null : _upload,
//               icon: _busy
//                   ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
//                   : const Icon(Icons.cloud_upload),
//               label: Text(_busy ? 'Uploading...' : 'Upload & Scan'),
//             ),
//           ),
//         ]),
//       ),
//     );
//   }
// }
