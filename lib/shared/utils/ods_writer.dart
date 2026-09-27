import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// The media type of an OpenDocument spreadsheet (`.ods`).
const odsMimeType = 'application/vnd.oasis.opendocument.spreadsheet';

/// One cell of an [OdsSheet].
sealed class OdsCell {
  const OdsCell();

  const factory OdsCell.text(String value, {bool bold}) = OdsText;
  const factory OdsCell.number(double value, {int? decimals}) = OdsNumber;

  /// A share, 0–1, shown as a percentage.
  const factory OdsCell.percent(double value) = OdsPercent;
  const factory OdsCell.empty() = OdsEmpty;
}

class OdsText extends OdsCell {
  const OdsText(this.value, {this.bold = false});

  final String value;
  final bool bold;
}

class OdsNumber extends OdsCell {
  const OdsNumber(this.value, {this.decimals});

  final double value;

  /// Decimal places to show. `null` shows the number as it is.
  final int? decimals;
}

class OdsPercent extends OdsCell {
  const OdsPercent(this.value);

  final double value;
}

class OdsEmpty extends OdsCell {
  const OdsEmpty();
}

/// One sheet (tab) of a spreadsheet. The first column is laid out wide for
/// names, the rest narrow for values.
class OdsSheet {
  const OdsSheet({required this.name, required this.rows});

  final String name;
  final List<List<OdsCell>> rows;
}

/// Writes [sheets] as an OpenDocument spreadsheet, readable by LibreOffice,
/// Excel, Numbers and Google Sheets.
///
/// The file is a zip holding `mimetype` (first and uncompressed, so the type
/// can be read from a fixed offset), the manifest, and the sheets in
/// `content.xml`.
Uint8List encodeOds(List<OdsSheet> sheets) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.bytes('mimetype', ascii.encode(odsMimeType))
        ..compression = CompressionType.none,
    )
    ..addFile(ArchiveFile.string('META-INF/manifest.xml', _manifest))
    ..addFile(ArchiveFile.string('styles.xml', _styles))
    ..addFile(ArchiveFile.string('content.xml', odsContentXml(sheets)));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const _namespaces =
    'xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" '
    'xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" '
    'xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" '
    'xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" '
    'xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" '
    'xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0"';

const _manifest =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<manifest:manifest '
    'xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0" '
    'manifest:version="1.3">'
    '<manifest:file-entry manifest:full-path="/" manifest:version="1.3" '
    'manifest:media-type="$odsMimeType"/>'
    '<manifest:file-entry manifest:full-path="content.xml" '
    'manifest:media-type="text/xml"/>'
    '<manifest:file-entry manifest:full-path="styles.xml" '
    'manifest:media-type="text/xml"/>'
    '</manifest:manifest>';

const _styles =
    '<?xml version="1.0" encoding="UTF-8"?>'
    '<office:document-styles $_namespaces office:version="1.3">'
    '<office:styles/>'
    '</office:document-styles>';

/// Decimal places that get a cell style of their own; others fall back to
/// the number as it is.
const _decimalStyles = [0, 1, 2];

const _automaticStyles =
    '<office:automatic-styles>'
    '<number:number-style style:name="N0">'
    '<number:number number:decimal-places="0" number:min-integer-digits="1"/>'
    '</number:number-style>'
    '<number:number-style style:name="N1">'
    '<number:number number:decimal-places="1" '
    'number:min-decimal-places="1" number:min-integer-digits="1"/>'
    '</number:number-style>'
    '<number:number-style style:name="N2">'
    '<number:number number:decimal-places="2" '
    'number:min-decimal-places="2" number:min-integer-digits="1"/>'
    '</number:number-style>'
    '<number:percentage-style style:name="NP">'
    '<number:number number:decimal-places="0" number:min-integer-digits="1"/>'
    '<number:text>%</number:text>'
    '</number:percentage-style>'
    '<style:style style:name="coName" style:family="table-column">'
    '<style:table-column-properties style:column-width="5cm"/>'
    '</style:style>'
    '<style:style style:name="coValue" style:family="table-column">'
    '<style:table-column-properties style:column-width="2.6cm"/>'
    '</style:style>'
    '<style:style style:name="ceBold" style:family="table-cell">'
    '<style:text-properties fo:font-weight="bold"/>'
    '</style:style>'
    '<style:style style:name="ceN0" style:family="table-cell" '
    'style:data-style-name="N0"/>'
    '<style:style style:name="ceN1" style:family="table-cell" '
    'style:data-style-name="N1"/>'
    '<style:style style:name="ceN2" style:family="table-cell" '
    'style:data-style-name="N2"/>'
    '<style:style style:name="ceP" style:family="table-cell" '
    'style:data-style-name="NP"/>'
    '</office:automatic-styles>';

/// The `content.xml` of a spreadsheet holding [sheets].
String odsContentXml(List<OdsSheet> sheets) {
  final buffer = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8"?>')
    ..write('<office:document-content $_namespaces office:version="1.3">')
    ..write(_automaticStyles)
    ..write('<office:body><office:spreadsheet>');

  final usedNames = <String>{};
  for (final sheet in sheets) {
    final name = _uniqueSheetName(sheet.name, usedNames);
    final columns = sheet.rows.fold(
      0,
      (max, row) => row.length > max ? row.length : max,
    );
    buffer.write('<table:table table:name="${_escape(name)}">');
    buffer.write('<table:table-column table:style-name="coName"/>');
    if (columns > 1) {
      buffer.write(
        '<table:table-column table:style-name="coValue" '
        'table:number-columns-repeated="${columns - 1}"/>',
      );
    }
    for (final row in sheet.rows) {
      buffer.write('<table:table-row>');
      for (final cell in row) {
        _writeCell(buffer, cell);
      }
      buffer.write('</table:table-row>');
    }
    if (sheet.rows.isEmpty) {
      // A table needs at least one row to be valid.
      buffer.write('<table:table-row><table:table-cell/></table:table-row>');
    }
    buffer.write('</table:table>');
  }

  buffer.write('</office:spreadsheet></office:body></office:document-content>');
  return buffer.toString();
}

void _writeCell(StringBuffer buffer, OdsCell cell) {
  switch (cell) {
    case OdsEmpty():
      buffer.write('<table:table-cell/>');
    case OdsText(:final value, :final bold):
      if (value.isEmpty) {
        buffer.write('<table:table-cell/>');
        return;
      }
      final style = bold ? ' table:style-name="ceBold"' : '';
      buffer.write('<table:table-cell office:value-type="string"$style>');
      for (final line in value.split('\n')) {
        buffer.write('<text:p>${_escape(line)}</text:p>');
      }
      buffer.write('</table:table-cell>');
    case OdsNumber(:final value, :final decimals):
      if (!value.isFinite) {
        buffer.write('<table:table-cell/>');
        return;
      }
      final style = decimals != null && _decimalStyles.contains(decimals)
          ? ' table:style-name="ceN$decimals"'
          : '';
      buffer.write(
        '<table:table-cell office:value-type="float" '
        'office:value="${_number(value)}"$style>'
        '<text:p>${decimals == null ? _number(value) : value.toStringAsFixed(decimals)}</text:p>'
        '</table:table-cell>',
      );
    case OdsPercent(:final value):
      if (!value.isFinite) {
        buffer.write('<table:table-cell/>');
        return;
      }
      buffer.write(
        '<table:table-cell office:value-type="percentage" '
        'office:value="${_number(value)}" table:style-name="ceP">'
        '<text:p>${(value * 100).toStringAsFixed(0)} %</text:p>'
        '</table:table-cell>',
      );
  }
}

/// A number the way ODF stores it: a dot for the decimal point, and no
/// trailing ".0" on whole numbers.
String _number(double value) {
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toInt().toString();
  }
  return value.toString();
}

/// Sheet names may not hold `[]*?:/\` or run longer than 31 characters,
/// which Excel refuses, and must differ from each other.
String _uniqueSheetName(String raw, Set<String> used) {
  var base = raw.replaceAll(RegExp(r"[\[\]*?:/\\']"), ' ').trim();
  if (base.isEmpty) base = 'Sheet';
  if (base.length > 31) base = base.substring(0, 31);
  var name = base;
  var suffix = 2;
  while (!used.add(name.toLowerCase())) {
    final tail = ' ($suffix)';
    name =
        '${base.length + tail.length > 31 ? base.substring(0, 31 - tail.length) : base}$tail';
    suffix++;
  }
  return name;
}

final _invalidXmlChars = RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]');

String _escape(String value) => value
    .replaceAll(_invalidXmlChars, '')
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
