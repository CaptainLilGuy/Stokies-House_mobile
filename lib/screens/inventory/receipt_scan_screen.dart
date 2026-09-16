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
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  bool _isProcessing = false;
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 85, // slight compression, keeps OCR quality while trimming file size
        );
        if (picked != null) {
          setState(() => _imageFile = File(picked.path));
        }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera / gallery: $e')),
        );
      }
    }
  }

  void _retake() {
    setState (() => _imageFile = null);
  }

  Future<void> _useThisPhoto() async {
    if (_imageFile == null) return;
    setState(() => _isProcessing = true);
    
    try {
      final inputImage = InputImage.fromFile(_imageFile!);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      final String rawText = recognizedText.text;

      if(rawText.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text detected — try retaking with better lighting.'))
          );
        }
        return;
      }

      final parsedData = await ApiService().parseReceipt(rawText);
      
      if (mounted) {
        context.push('/inventory/scan-receipt/review', extra: parsedData);
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reach server: ${e.message}')),
        );
      }
    } catch (e){
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong: $e')),
        );
      }
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
      body: _imageFile == null ? _buildCaptureOptions() : _buildPreview(),
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
            Container(
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
                  child: Text(
                    'Tip: make sure item names, quantities, and prices are all fully visible in the frame.',
                    style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt), 
              label: const Text('Take photo'),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Choose from gallery'),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(_imageFile!, fit: BoxFit.contain),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Check: names, quantities, and prices are all fully in frame?',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _retake,
                  child: const Text('Retake'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _useThisPhoto,
                  child: _isProcessing
                      ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Use this photo'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  } 
}