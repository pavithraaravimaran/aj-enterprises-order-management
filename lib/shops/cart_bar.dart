import 'package:flutter/material.dart';

class CartBar extends StatelessWidget {
  final double total;
  final VoidCallback onPlaceOrder;

  const CartBar({
    super.key,
    required this.total,
    required this.onPlaceOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: Container(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Total : ₹${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: onPlaceOrder,
              child: const Text("Place Order"),
            )
          ],
        ),
      ),
    );
  }
}