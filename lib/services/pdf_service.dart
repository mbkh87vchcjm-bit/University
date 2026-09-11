import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart' as intl;
import '../models/visit.dart';

class PdfService {
  static Future<Uint8List> generateInvoicePdf(Visit visit) async {
    final pdf = pw.Document();

    // Load local font assets directly to guarantee offline Arabic rendering
    final ByteData fontByteData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
    final ByteData fontBoldByteData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

    final pw.Font cairoRegular = pw.Font.ttf(fontByteData);
    final pw.Font cairoBold = pw.Font.ttf(fontBoldByteData);

    // Also load app logo image if available
    pw.MemoryImage? logoImage;
    try {
      final ByteData logoByteData = await rootBundle.load('assets/images/logo.png');
      logoImage = pw.MemoryImage(logoByteData.buffer.asUint8List());
    } catch (_) {}

    final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(
          base: cairoRegular,
          bold: cairoBold,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 42,
                            height: 42,
                            child: pw.Image(logoImage),
                          ),
                          pw.SizedBox(width: 8),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'مركز طبيب أشعة التخصصي',
                              style: pw.TextStyle(
                                font: cairoBold,
                                fontSize: 14,
                                color: PdfColors.blue900,
                              ),
                            ),
                            pw.Text(
                              'تشخيص دقيق - عناية متكاملة',
                              style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'هاتف: 770000000 | المركز الرئيسي',
                              style: pw.TextStyle(font: cairoRegular, fontSize: 8, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'فاتورة خدمات أشعة',
                          style: pw.TextStyle(font: cairoBold, fontSize: 13, color: PdfColors.blue800),
                        ),
                        pw.Text(
                          'رقم الفاتورة: ${visit.invoiceNumber}',
                          style: pw.TextStyle(font: cairoBold, fontSize: 9),
                        ),
                        pw.Text(
                          'التاريخ: ${visit.visitDate.split("T").first}',
                          style: pw.TextStyle(font: cairoRegular, fontSize: 8),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 8),

                // Patient Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('اسم المريض: ${visit.patientName}', style: pw.TextStyle(font: cairoBold, fontSize: 10)),
                          pw.Text('رقم الهاتف: ${visit.patientPhone}', style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الطبيب المحيل: ${visit.doctorName ?? "بدون إحالة"}', style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                          pw.Text('طريقة الدفع: ${visit.paymentMethod}', style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('نوع الأشعة / الفحص', style: pw.TextStyle(font: cairoBold, color: PdfColors.white, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('السعر الأصلي', style: pw.TextStyle(font: cairoBold, color: PdfColors.white, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('الخصم', style: pw.TextStyle(font: cairoBold, color: PdfColors.white, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('الصافي', style: pw.TextStyle(font: cairoBold, color: PdfColors.white, fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(visit.serviceName, style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${currencyFormatter.format(visit.servicePrice)} ريال', style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${currencyFormatter.format(visit.discount)} ريال', style: pw.TextStyle(font: cairoRegular, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('${currencyFormatter.format(visit.netAmount)} ريال', style: pw.TextStyle(font: cairoBold, fontSize: 9)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Financial Summary
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue800),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ الإجمالي:', style: pw.TextStyle(font: cairoBold, fontSize: 10)),
                          pw.Text('${currencyFormatter.format(visit.netAmount)} ريال', style: pw.TextStyle(font: cairoBold, fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ المدفوع:', style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: PdfColors.green800)),
                          pw.Text('${currencyFormatter.format(visit.paidAmount)} ريال', style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: PdfColors.green800)),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ المتبقي:', style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: visit.remainingAmount > 0 ? PdfColors.red800 : PdfColors.black)),
                          pw.Text('${currencyFormatter.format(visit.remainingAmount)} ريال', style: pw.TextStyle(font: cairoRegular, fontSize: 9, color: visit.remainingAmount > 0 ? PdfColors.red800 : PdfColors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Footer
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('شكراً لزيارتكم - نتمنى لكم دوام الصحة والعافية', style: pw.TextStyle(font: cairoRegular, fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('المطور محمد الفقيه', style: pw.TextStyle(font: cairoRegular, fontSize: 8, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> printInvoice(Visit visit) async {
    final pdfBytes = await generateInvoicePdf(visit);
    await Printing.layoutPdf(onLayout: (_) => pdfBytes);
  }
}
