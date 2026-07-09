import 'package:flutter/material.dart';

class OrderDetailScreen extends StatelessWidget {
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final String status;
  final dynamic createdAt;
  final Map<String, Map<String, dynamic>> cart;

  const OrderDetailScreen({
    super.key,
    required this.shopName,
    required this.shopPhone,
    required this.shopAddress,
    required this.status,
    required this.createdAt,
    required this.cart,
  });

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = getStatusColor(status);

    // 💰 TOTAL (FIXED WITH FREE QTY)
    double grandTotal = 0;

    for (var item in cart.values) {
      final price = (item['price'] ?? 0).toDouble();

      final paidQty = item['paidQty'] ?? 0;
      final freeQty = item['freeQty'] ?? 0;

      final qty = paidQty + freeQty; // ✅ FIX

      final gst = (item['gst'] ?? 0).toDouble();

      final subtotal = price * qty;
      final gstAmount = subtotal * gst / 100;
      final itemTotal = subtotal + gstAmount;

      grandTotal += itemTotal;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        title: Text(
          shopName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🏪 SHOP INFO
            Text(
              shopName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 4),
            Text("📞 $shopPhone"),
            Text("📍 $shopAddress"),

            const SizedBox(height: 8),

            // STATUS
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              "Products",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 10),

            // 📦 ITEMS
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cart.length,
              itemBuilder: (_, index) {
                final item = cart.values.elementAt(index);

                final price = (item['price'] ?? 0).toDouble();

                final paidQty = item['paidQty'] ?? 0;
                final freeQty = item['freeQty'] ?? 0;

                final qty = paidQty + freeQty; // ✅ FIX

                final gst = (item['gst'] ?? 0).toDouble();

                final subtotal = price * qty;
                final gstAmount = subtotal * gst / 100;
                final itemTotal = subtotal + gstAmount;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(
                              item['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // ✅ QTY + GST (Moved above + Increased font size)
                            Text(
                              freeQty > 0
                                  ? "$paidQty + $freeQty free × ₹${price.toStringAsFixed(2)} + GST ${gst.toStringAsFixed(0)}%"
                                  : "$paidQty × ₹${price.toStringAsFixed(2)} + GST ${gst.toStringAsFixed(0)}%",
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 3),

                            // ✅ MRP + Retail below
                            Text(
                              "MRP: ₹${(item['mrp'] ?? 0)}   Retail: ₹${price.toStringAsFixed(2)}",
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 2),

                            if ((item['note'] ?? '').toString().isNotEmpty)
                              Text(
                                "Note: ${item['note']}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ),

                      Text(
                        "₹${itemTotal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 💰 TOTAL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  const Text(
                    "TOTAL AMOUNT",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "₹ ${grandTotal.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}