import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../shared/widgets/app_bar_title.dart';

/// Shows a stored exam PDF (task sheet or Erwartungshorizont).
class ExamPdfScreen extends StatelessWidget {
  const ExamPdfScreen({
    required this.file,
    required this.title,
    this.subtitle,
    super.key,
  });

  final File file;
  final String title;
  final String? subtitle;

  static Future<void> open(
    BuildContext context, {
    required File file,
    required String title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ExamPdfScreen(file: file, title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title: title, subtitle: subtitle),
      ),
      body: PdfViewer.file(file.path),
    );
  }
}
