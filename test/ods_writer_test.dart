import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:classi/shared/utils/ods_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sheets = [
    OdsSheet(
      name: 'Grades',
      rows: const [
        [OdsCell.text('Name', bold: true), OdsCell.text('Ø', bold: true)],
        [OdsCell.text('Lovelace, Ada'), OdsCell.number(1.25, decimals: 2)],
        [OdsCell.text('A & <B>'), OdsCell.empty()],
      ],
    ),
    const OdsSheet(
      name: 'Attendance',
      rows: [
        [OdsCell.text('x'), OdsCell.percent(0.875)],
      ],
    ),
  ];

  test('starts with the uncompressed mimetype, as ODF requires', () {
    final bytes = encodeOds(sheets);

    // The type sits at a fixed offset: after the 30-byte local header and
    // the 8-byte name "mimetype".
    expect(ascii.decode(bytes.sublist(30, 38)), 'mimetype');
    expect(
      ascii.decode(bytes.sublist(38, 38 + odsMimeType.length)),
      odsMimeType,
    );

    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.files.map((f) => f.name), [
      'mimetype',
      'META-INF/manifest.xml',
      'styles.xml',
      'content.xml',
    ]);
  });

  test('writes typed cells and escapes text', () {
    final xml = odsContentXml(sheets);

    expect(xml, contains('<table:table table:name="Grades">'));
    expect(xml, contains('<table:table table:name="Attendance">'));
    expect(
      xml,
      contains(
        '<table:table-cell office:value-type="float" office:value="1.25" '
        'table:style-name="ceN2"><text:p>1.25</text:p></table:table-cell>',
      ),
    );
    expect(
      xml,
      contains('office:value-type="percentage" office:value="0.875"'),
    );
    expect(xml, contains('<text:p>A &amp; &lt;B&gt;</text:p>'));
    expect(xml, contains('table:style-name="ceBold"'));
  });

  test('makes sheet names valid and unique', () {
    final xml = odsContentXml(const [
      OdsSheet(name: 'a/b', rows: []),
      OdsSheet(name: 'A b', rows: []),
      OdsSheet(name: '', rows: []),
    ]);

    expect(xml, contains('table:name="a b"'));
    expect(xml, contains('table:name="A b (2)"'));
    expect(xml, contains('table:name="Sheet"'));
  });
}
