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

    final fontData = pw.Font.ttf(
  await rootBundle.load('assets/fonts/Cairo-Regular.ttf'),
);

final fontBoldData = fontData;

    final currencyFormatter = intl.NumberFormat('#,##0', 'ar');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(16),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'مركز طبيب أشعة التخصصي',
                          style: pw.TextStyle(
                            font: fontBoldData,
                            fontSize: 16,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'تشخيص دقيق - عناية متكاملة',
                          style: pw.TextStyle(font: fontData, fontSize: 10, color: PdfColors.grey700),
                        ),
                        pw.Text(
                          'هاتف: 770000000 | العنوان: المركز الرئيسي',
                          style: pw.TextStyle(font: fontData, fontSize: 8, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'فاتورة خدمات أشعة',
                          style: pw.TextStyle(font: fontBoldData, fontSize: 14, color: PdfColors.blue800),
                        ),
                        pw.Text(
                          'رقم الفاتورة: ${visit.invoiceNumber}',
                          style: pw.TextStyle(font: fontBoldData, fontSize: 10),
                        ),
                        pw.Text(
                          'التاريخ: ${visit.visitDate.split("T").first}',
                          style: pw.TextStyle(font: fontData, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 1.5, color: PdfColors.blue900),
                pw.SizedBox(height: 10),

                // Patient Info Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
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
                          pw.Text('اسم المريض: ${visit.patientName}', style: pw.TextStyle(font: fontBoldData, fontSize: 11)),
                          pw.Text('رقم الهاتف: ${visit.patientPhone}', style: pw.TextStyle(font: fontData, fontSize: 10)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('الطبيب المحيل: ${visit.doctorName ?? "بدون إحالة"}', style: pw.TextStyle(font: fontData, fontSize: 10)),
                          pw.Text('طريقة الدفع: ${visit.paymentMethod}', style: pw.TextStyle(font: fontData, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 15),

                // Invoice Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('نوع الأشعة / الفحص', style: pw.TextStyle(font: fontBoldData, color: PdfColors.white, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('السعر الأصلي', style: pw.TextStyle(font: fontBoldData, color: PdfColors.white, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('الخصم', style: pw.TextStyle(font: fontBoldData, color: PdfColors.white, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('الصافي', style: pw.TextStyle(font: fontBoldData, color: PdfColors.white, fontSize: 10)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(visit.serviceName, style: pw.TextStyle(font: fontData, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${currencyFormatter.format(visit.servicePrice)} ريال', style: pw.TextStyle(font: fontData, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${currencyFormatter.format(visit.discount)} ريال', style: pw.TextStyle(font: fontData, fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${currencyFormatter.format(visit.netAmount)} ريال', style: pw.TextStyle(font: fontBoldData, fontSize: 10)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                // Summary Total Box
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.blue800),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ الإجمالي:', style: pw.TextStyle(font: fontBoldData, fontSize: 11)),
                          pw.Text('${currencyFormatter.format(visit.netAmount)} ريال', style: pw.TextStyle(font: fontBoldData, fontSize: 11)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ المدفوع:', style: pw.TextStyle(font: fontData, fontSize: 10, color: PdfColors.green800)),
                          pw.Text('${currencyFormatter.format(visit.paidAmount)} ريال', style: pw.TextStyle(font: fontData, fontSize: 10, color: PdfColors.green800)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('المبلغ المتبقي:', style: pw.TextStyle(font: fontData, fontSize: 10, color: visit.remainingAmount > 0 ? PdfColors.red800 : PdfColors.black)),
                          pw.Text('${currencyFormatter.format(visit.remainingAmount)} ريال', style: pw.TextStyle(font: fontData, fontSize: 10, color: visit.remainingAmount > 0 ? PdfColors.red800 : PdfColors.black)),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.Spacer(),

                // Footer with Developer Attribution
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('شكراً لزيارتكم - نتمنى لكم دوام الصحة والعافية', style: pw.TextStyle(font: fontData, fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('المطور محمد الفقيه', style: pw.TextStyle(font: fontData, fontSize: 8, color: PdfColors.grey600)),
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
