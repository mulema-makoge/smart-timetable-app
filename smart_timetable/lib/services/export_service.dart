import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import '../models/timetable_model.dart';

class ExportService {
  bool _isExporting = false;

  // Export timetable as PDF
  Future<void> exportPDF(List<ScheduleSlot> slots) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      final pdf = pw.Document();

      final dayOrder = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      slots.sort((a, b) {
        final dayCompare = dayOrder
            .indexOf(a.day)
            .compareTo(dayOrder.indexOf(b.day));
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            pw.Text(
              'Smart Timetable',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue900,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Generated Timetable - ${DateTime.now().toString().substring(0, 10)}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 20),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(1.5),
                4: const pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: ['Day', 'Course', 'Lecturer', 'Room', 'Time']
                      .map(
                        (h) => pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            h,
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                ...slots.asMap().entries.map((entry) {
                  final i = entry.key;
                  final slot = entry.value;
                  final isEven = i % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEven ? PdfColors.white : PdfColors.blue50,
                    ),
                    children:
                        [
                              slot.day,
                              slot.courseName,
                              slot.lecturerName,
                              slot.roomName,
                              '${slot.startTime} to ${slot.endTime}',
                            ]
                            .map(
                              (cell) => pw.Padding(
                                padding: const pw.EdgeInsets.all(8),
                                child: pw.Text(
                                  cell,
                                  style: const pw.TextStyle(fontSize: 9),
                                ),
                              ),
                            )
                            .toList(),
                  );
                }),
              ],
            ),
          ],
        ),
      );

      final bytes = await pdf.save();
      _downloadFile(bytes, 'timetable.pdf', 'application/pdf');
    } catch (e) {
      debugPrint('PDF export error: $e');
      rethrow;
    } finally {
      _isExporting = false;
    }
  }

  // Export timetable as Excel
  Future<void> exportExcel(List<ScheduleSlot> slots) async {
    if (_isExporting) return;
    _isExporting = true;

    try {
      final excel = Excel.createExcel();
      final sheet = excel['Timetable'];

      // Remove default sheet
      excel.delete('Sheet1');

      final headers = [
        'Day',
        'Course',
        'Lecturer',
        'Room',
        'Start Time',
        'End Time',
      ];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.fromHexString('#1F5C8B'),
          fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
        );
      }

      final dayOrder = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      slots.sort((a, b) {
        final dayCompare = dayOrder
            .indexOf(a.day)
            .compareTo(dayOrder.indexOf(b.day));
        if (dayCompare != 0) return dayCompare;
        return a.startTime.compareTo(b.startTime);
      });

      for (int i = 0; i < slots.length; i++) {
        final slot = slots[i];
        final rowData = [
          slot.day,
          slot.courseName,
          slot.lecturerName,
          slot.roomName,
          slot.startTime,
          slot.endTime,
        ];
        for (int j = 0; j < rowData.length; j++) {
          sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1))
              .value = TextCellValue(
            rowData[j],
          );
        }
      }

      final bytes = excel.save();
      if (bytes != null) {
        _downloadFile(
          Uint8List.fromList(bytes),
          'timetable.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      }
    } catch (e) {
      debugPrint('Excel export error: $e');
      rethrow;
    } finally {
      _isExporting = false;
    }
  }

  // Trigger browser file download
  void _downloadFile(Uint8List bytes, String filename, String mimeType) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..setAttribute('download', filename)
      ..click();
    web.URL.revokeObjectURL(anchor.href);
  }
}
