import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

final ordersRef =
FirebaseFirestore.instance.collection('orders');

// 📅 DATE
String formatDate(Timestamp ts) {
  return DateFormat('dd MMM yyyy, hh:mm a')
      .format(ts.toDate());
}

// 🎨 STATUS COLOR
Color getStatusColor(String status) {
  switch (status) {
    case 'delivered':
      return const Color(0xFF2E7D32);
    case 'cancelled':
      return Colors.red;
    default:
      return const Color(0xFFF9A825);
  }
}

// ❌ DELETE
Future<void> deleteOrder(String id) async {
  await ordersRef.doc(id).delete();
}

// ❌ CANCEL
Future<void> cancelOrder(String id) async {
  await ordersRef.doc(id).update({'status': 'cancelled'});
}

// ✅ DELIVER
Future<void> markDelivered(
    BuildContext context, String id) async {
  final ok = await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text("Confirm"),
      content:
      const Text("Mark as delivered & remove?"),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.pop(context, false),
          child: const Text("No"),
        ),

        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1565C0),
            foregroundColor: Colors.white,
          ),
          onPressed: () =>
              Navigator.pop(context, true),
          child: const Text("Yes"),
        ),
      ],
    ),
  );

  if (ok == true) {
    await ordersRef.doc(id).delete();
  }
}
/// 📄 PDF
Future<void> exportToPdf(
    Map<String, dynamic> order) async {

  final pdf = pw.Document();

  final items =
  List<Map<String, dynamic>>.from(
    order['items'] ?? [],
  );

  final shopName =
      order['shopName'] ?? '';

  final phone =
      order['phone'] ?? '';

  final address =
      order['address'] ?? '';

  final note =
      order['note'] ?? '';

  final total =
  (order['total'] ?? 0)
      .toDouble();

  pdf.addPage(
    pw.MultiPage(
      margin:
      const pw.EdgeInsets.all(24),

      build: (_) {
        return [

          // 🧾 TITLE
          pw.Center(
            child: pw.Text(
              "ORDER INVOICE",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight:
                pw.FontWeight.bold,
              ),
            ),
          ),

          pw.SizedBox(height: 25),

          // 🏪 SHOP DETAILS
          pw.Text(
            "Shop Name : $shopName",
            style: pw.TextStyle(
              fontSize: 15,
              fontWeight:
              pw.FontWeight.bold,
            ),
          ),

          pw.SizedBox(height: 6),

          pw.Text(
            "Phone : $phone",
            style:
            const pw.TextStyle(
              fontSize: 11,
            ),
          ),

          pw.SizedBox(height: 4),

          pw.Text(
            "Address : $address",
            style:
            const pw.TextStyle(
              fontSize: 11,
            ),
          ),

          if (note
              .toString()
              .trim()
              .isNotEmpty)
            pw.Column(
              crossAxisAlignment:
              pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(height: 10),

                pw.Text(
                  "Note : $note",
                  style:
                  const pw.TextStyle(
                    fontSize: 11,
                  ),
                ),
              ],
            ),

          pw.SizedBox(height: 25),

          // 📦 HEADER
          pw.Container(
            padding:
            const pw.EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 6,
            ),

            decoration:
            const pw.BoxDecoration(
              border: pw.Border(
                bottom:
                pw.BorderSide(
                  width: 1,
                  color: PdfColors.grey400,
                ),
              ),
            ),

            child: pw.Row(
              children: [

                // PRODUCT
                pw.Expanded(
                  flex: 4,
                  child: pw.Text(
                    "Product",
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // QTY
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "Qty",
                    textAlign:
                    pw.TextAlign.center,
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // MRP
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "MRP",
                    textAlign:
                    pw.TextAlign.right,
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // RETAIL
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "Retail",
                    textAlign:
                    pw.TextAlign.right,
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // GST
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "GST",
                    textAlign:
                    pw.TextAlign.right,
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),

                // TOTAL
                pw.Expanded(
                  flex: 2,
                  child: pw.Text(
                    "Total",
                    textAlign:
                    pw.TextAlign.right,
                    style:
                    pw.TextStyle(
                      fontWeight:
                      pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 5),

          // 📦 ITEMS
          ...items.map((i) {

            final name =
                i['name'] ?? '';

            final productNote =
                i['note'] ?? '';

            final mrp =
            (i['mrp'] ?? 0)
                .toDouble();

            final price =
            (i['price'] ?? 0)
                .toDouble();

            final gst =
            (i['gst'] ?? 0)
                .toDouble();

            final paidQty =
                i['paidQty'] ?? 0;

            final freeQty =
                i['freeQty'] ?? 0;

            final itemTotal =
                price * paidQty;

            final gstAmount =
                itemTotal *
                    gst /
                    100;

            final finalTotal =
                itemTotal +
                    gstAmount;

            return pw.Container(
              padding:
              const pw.EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 6,
              ),

              decoration:
              const pw.BoxDecoration(
                border: pw.Border(
                  bottom:
                  pw.BorderSide(
                    width: 0.5,
                    color:
                    PdfColors.grey300,
                  ),
                ),
              ),

              child: pw.Row(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,

                children: [

                  // PRODUCT
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment:
                      pw.CrossAxisAlignment.start,

                      children: [

                        // PRODUCT NAME
                        pw.Text(
                          name,
                          style:
                          const pw.TextStyle(
                            fontSize: 10,
                          ),
                        ),

                        // NOTE
                        if (productNote
                            .toString()
                            .trim()
                            .isNotEmpty)
                          pw.Padding(
                            padding:
                            const pw.EdgeInsets.only(
                              top: 2,
                            ),

                            child: pw.Text(
                              "Note: $productNote",
                              style:
                              pw.TextStyle(
                                fontSize: 8,
                                color:
                                PdfColors.grey700,
                                fontStyle:
                                pw.FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // QTY
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      freeQty > 0
                          ? "$paidQty+$freeQty"
                          : "$paidQty",

                      textAlign:
                      pw.TextAlign.center,

                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // MRP
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "Rs.${mrp.toStringAsFixed(2)}",

                      textAlign:
                      pw.TextAlign.right,

                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // RETAIL
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "Rs.${price.toStringAsFixed(2)}",

                      textAlign:
                      pw.TextAlign.right,

                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // GST
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "${gst.toStringAsFixed(0)}%",

                      textAlign:
                      pw.TextAlign.right,

                      style:
                      const pw.TextStyle(
                        fontSize: 10,
                      ),
                    ),
                  ),

                  // TOTAL
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      "Rs.${finalTotal.toStringAsFixed(2)}",

                      textAlign:
                      pw.TextAlign.right,

                      style:
                      pw.TextStyle(
                        fontSize: 10,
                        fontWeight:
                        pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          pw.SizedBox(height: 20),

          // 💰 GRAND TOTAL
          pw.Align(
            alignment:
            pw.Alignment.centerRight,

            child: pw.Container(
              padding:
              const pw.EdgeInsets.all(10),

              child: pw.Text(
                "Grand Total : Rs.${total.toStringAsFixed(2)}",

                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight:
                  pw.FontWeight.bold,
                ),
              ),
            ),
          ),

          pw.SizedBox(height: 30),

          // 🙏 FOOTER
          pw.Center(
            child: pw.Text(
              "Thank You!",

              style: pw.TextStyle(
                fontStyle:
                pw.FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ),
        ];
      },
    ),
  );

  await Printing.sharePdf(
    bytes: await pdf.save(),

    filename:
    "order_${DateTime.now().millisecondsSinceEpoch}.pdf",
  );
}