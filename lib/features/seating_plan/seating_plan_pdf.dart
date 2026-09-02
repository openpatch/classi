import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Renders a seating plan as a single printable page.
///
/// Names only — the avatars a teacher recognises on screen are noise on paper,
/// and a printed plan is usually there to be read by someone who does not know
/// the class yet, such as a substitute teacher.
///
/// Seats are laid out exactly as they sit on the plan: a cell with nobody in it
/// stays blank, so the shape of the room survives the trip to paper. Students
/// in [nameById] without a position are listed underneath, the way the grid
/// keeps them next to the plan.
Future<Uint8List> buildSeatingPlanPdf({
  required String title,
  required Map<int, String> nameById,
  required Map<int, ({int col, int row})> positions,
  String? subtitle,
  String? unplacedLabel,
}) {
  final placed = {
    for (final entry in positions.entries)
      if (nameById.containsKey(entry.key)) entry.key: entry.value,
  };
  final unplaced = [
    for (final entry in nameById.entries)
      if (!placed.containsKey(entry.key)) entry.value,
  ]..sort();

  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.all(28),
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          if (subtitle != null && subtitle.isNotEmpty)
            pw.Text(
              subtitle,
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 14),
          pw.Expanded(child: _seats(placed: placed, nameById: nameById)),
          if (unplaced.isNotEmpty) ...[
            pw.SizedBox(height: 12),
            if (unplacedLabel != null && unplacedLabel.isNotEmpty)
              pw.Text(
                unplacedLabel,
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey700,
                ),
              ),
            pw.Text(unplaced.join(' · '), style: const pw.TextStyle(fontSize: 10)),
          ],
        ],
      ),
    ),
  );
  return document.save();
}

pw.Widget _seats({
  required Map<int, ({int col, int row})> placed,
  required Map<int, String> nameById,
}) {
  if (placed.isEmpty) return pw.SizedBox();

  final columns = placed.values.map((p) => p.col);
  final rows = placed.values.map((p) => p.row);
  final firstColumn = columns.reduce((a, b) => a < b ? a : b);
  final lastColumn = columns.reduce((a, b) => a > b ? a : b);
  final firstRow = rows.reduce((a, b) => a < b ? a : b);
  final lastRow = rows.reduce((a, b) => a > b ? a : b);

  final studentAt = <(int, int), String>{
    for (final entry in placed.entries)
      (entry.value.col, entry.value.row): nameById[entry.key]!,
  };

  return pw.Column(
    children: [
      for (var row = firstRow; row <= lastRow; row++)
        pw.Expanded(
          child: pw.Row(
            children: [
              for (var col = firstColumn; col <= lastColumn; col++)
                pw.Expanded(child: _seat(studentAt[(col, row)])),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _seat(String? name) {
  if (name == null) return pw.SizedBox();
  return pw.Container(
    margin: const pw.EdgeInsets.all(3),
    padding: const pw.EdgeInsets.all(4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Center(
      child: pw.Text(
        name,
        textAlign: pw.TextAlign.center,
        maxLines: 3,
        style: const pw.TextStyle(fontSize: 10),
      ),
    ),
  );
}
