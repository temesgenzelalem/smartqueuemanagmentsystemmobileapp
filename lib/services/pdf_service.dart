import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;

class PdfService {
  static Future<void> printReceipt(Map<String, dynamic> tx, String? receiptUrl) async {
    final pdf = pw.Document();

    // Fetch receipt image if available
    pw.MemoryImage? receiptImage;
    if (receiptUrl != null && receiptUrl.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(receiptUrl));
        if (response.statusCode == 200) {
          receiptImage = pw.MemoryImage(response.bodyBytes);
        }
      } catch (e) {
        // Silently fail if image cannot be loaded
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('TSEHAY BANK',
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Center(
                  child: pw.Text('Transaction Receipt',
                    style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.SizedBox(height: 32),
                _row('Transaction ID', tx['id'].toString()),
                _row('Queue Number', tx['queue_number']?.toString() ?? 'N/A'),
                _row('Type', tx['type']?.toString().toUpperCase() ?? 'N/A'),
                _row('Amount', '${tx['amount']} ETB'),
                _row('Account Number', tx['account_number']?.toString() ?? 'N/A'),
                _row('Date', tx['created_at']?.toString() ?? 'N/A'),
                pw.SizedBox(height: 32),
                if (receiptImage != null)
                  pw.Center(
                    child: pw.Image(receiptImage, height: 350),
                  ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(
                  child: pw.Text('Thank you for banking with Tsehay Bank',
                    style: const pw.TextStyle(fontSize: 10)),
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_${tx['queue_number'] ?? tx['id']}.pdf',
    );
  }

  static pw.Widget _row(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(value),
        ],
      ),
    );
  }
}
