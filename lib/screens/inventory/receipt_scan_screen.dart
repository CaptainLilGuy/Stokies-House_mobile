import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homeventory/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReceiptScanScreen extends StatefulWidget {
  const ReceiptScanScreen({super.key});

  @override
  State<ReceiptScanScreen> createState() => _ReceiptScanScreenState();
}

class _ReceiptScanScreenState extends State<ReceiptScanScreen> {
  static const int _maxPhotos = 4;

  final ImagePicker _picker = ImagePicker();
  final List<File> _images = [];
  int _selected = 0;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  int get _remaining => _maxPhotos - _images.length;

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _append(List<XFile> picked) {
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked.take(_remaining).map((x) => File(x.path)));
      _selected = _images.length - 1;
    });
  }

  Future<void> _addFromCamera() async {
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.camera, imageQuality: 85);
      if (picked != null) _append([picked]);
    } catch (e) {
      _snack('Could not access camera: $e');
    }
  }

  Future<void> _addFromGallery() async {
    try {
      List<XFile> picked;
      if (_remaining == 1) {
        // pickMultiImage requires limit >= 2
        final one = await _picker.pickImage(
            source: ImageSource.gallery, imageQuality: 85);
        picked = one == null ? [] : [one];
      } else {
        picked = await _picker.pickMultiImage(
            imageQuality: 85, limit: _remaining);
      }
      _append(picked);
    } catch (e) {
      _snack('Could not access gallery: $e');
    }
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take photo'),
            onTap: () { Navigator.pop(ctx); _addFromCamera(); },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () { Navigator.pop(ctx); _addFromGallery(); },
          ),
        ]),
      ),
    );
  }

  void _remove(int index) {
    setState(() {
      _images.removeAt(index);
      if (_selected >= _images.length) {
        _selected = _images.isEmpty ? 0 : _images.length - 1;
      }
    });
  }

  Future<void> _useThesePhotos() async {
    if (_images.isEmpty) return;
    setState(() => _isProcessing = true);

    try {
      final texts = <String>[];
      for (var i = 0; i < _images.length; i++) {
        final result = await _textRecognizer
            .processImage(InputImage.fromFile(_images[i]));
        if (result.text.trim().isEmpty) {
          if (mounted) setState(() => _selected = i);
          _snack('No text detected in photo ${i + 1} — remove it or retake with better lighting.');
          return;
        }
        texts.add(result.text);
      }

      final parsedData = await ApiService().parseReceipt(texts);
      if (mounted) {
        context.push('/inventory/scan-receipt/review', extra: parsedData);
      }
    } on DioException catch (e) {
      // _snack('Could not reach server: ${e.message}');
      _snack(parseApiError(e));

    } catch (e) {
      _snack('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/inventory'),
        ),
      ),
      body: _images.isEmpty ? _buildCaptureOptions() : _buildPreview(),
    );
  }

  Widget _buildCaptureOptions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Take a photo of your receipt, or choose one from your gallery.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            _tipBox(
              'Tip: make sure item names, quantities, and prices are all fully visible. '
              'Long receipt? You can add up to $_maxPhotos photos, top to bottom, '
              'overlapping by 2–3 items.',
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take photo'),
              onPressed: _addFromCamera,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
              onPressed: _addFromGallery,
            ),
          ],
        ),
      ),
    );
  }

  Widget _tipBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 20, color: Colors.amber.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 12, color: Colors.amber.shade900)),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_images[_selected], fit: BoxFit.contain),
            ),
          ),
        ),
        SizedBox(
          height: 76,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _images.length,
            // ignore: unnecessary_underscores
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (ctx, i) => GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 60,
                    height: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: i == _selected ? colors.primary : Colors.grey.shade300,
                        width: i == _selected ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.file(_images[i], fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: 4, bottom: 4,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.black54,
                      child: Text('${i + 1}',
                          style: const TextStyle(fontSize: 10, color: Colors.white)),
                    ),
                  ),
                  if (!_isProcessing)
                    Positioned(
                      right: -6, top: -6,
                      child: GestureDetector(
                        onTap: () => _remove(i),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.red,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _images.length > 1
                      ? 'Photos are read in order, top to bottom. Overlapping items are merged automatically.'
                      : 'Check: names, quantities, and prices are all fully in frame?',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Row(
            children: [
              if (_remaining > 0) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: Text('Add photo (${_images.length}/$_maxPhotos)'),
                    onPressed: _isProcessing ? null : _showAddSheet,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _useThesePhotos,
                  child: _isProcessing
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(_images.length == 1
                          ? 'Use this photo'
                          : 'Use ${_images.length} photos'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}