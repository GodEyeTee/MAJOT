// lib/features/ocr_scanner/presentation/pages/scanner_page.dart
import 'package:flutter/material.dart';

class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR Scanner')),
      body: const Center(child: Text('OCR Scanner Page - Placeholder')),
    );
  }
}
