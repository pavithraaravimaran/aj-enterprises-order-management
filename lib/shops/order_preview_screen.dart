import 'package:flutter/material.dart';
import 'package:untitled/shops/shop_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../home_screen.dart';
import '../orders/orders_screen.dart';
class OrderPreviewScreen extends StatefulWidget {
  final Map<String, Map<String, dynamic>> cart;

  final bool isEdit;
  final String? orderId;

  final String shopId;
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final String shopNote;


  const OrderPreviewScreen({
    super.key,
    required this.cart,
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.shopAddress,
    required this.shopNote,
    this.isEdit = false,
    this.orderId,
  });

  @override
  State<OrderPreviewScreen> createState() =>
      _OrderPreviewScreenState();
}

class _OrderPreviewScreenState
    extends State<OrderPreviewScreen> {
  late Map<String, Map<String, dynamic>> cart;

  @override
  void initState() {
    super.initState();

    cart = Map<String, Map<String, dynamic>>.from(
      widget.cart,
    );
  }

  // ---------------- QTY ----------------
  Future<void> placeOrder(
      Map<String, Map<String, dynamic>> updatedCart,
      double updatedTotal,
      {String? editOrderId}
      ) async {
    if (updatedCart.isEmpty) return;

    try {
      final data = {
        'shopId': widget.shopId,
        'shopName': widget.shopName,
        'phone': widget.shopPhone,
        'address': widget.shopAddress,
        'note': widget.shopNote,
        'items': updatedCart.values.toList(),
        'total': updatedTotal,
        'status': 'pending',
        'updatedAt': Timestamp.now(),
      };

      // ✅ UPDATE MODE
      if (editOrderId != null && editOrderId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(editOrderId)
            .update(data);
      }
      // ✅ CREATE MODE
      else {
        data['createdAt'] = Timestamp.now();

        await FirebaseFirestore.instance
            .collection('orders')
            .add(data);
      }

      if (!mounted) return;

      setState(() {
        cart.clear();
      });

      // ✅ SHOW SUCCESS DIALOG SAFELY
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: Text(
            (editOrderId != null && editOrderId.isNotEmpty)
                ? "Order updated successfully"
                : "Order placed successfully",
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context); // close dialog

                if (editOrderId != null && editOrderId.isNotEmpty) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HomeScreen(initialIndex: 0),
                    ),
                        (route) => false,
                  );
                } else {
                  // ✅ NEW ORDER FLOW (your existing 4 pop logic)
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                  //Navigator.pop(context);
                }
              },
              child: const Text("OK"),
            )
          ],
        ),
      );

    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Error"),
          content: Text("Something went wrong: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }
  void increaseQty(String key) {
    setState(() {
      cart[key]!['paidQty'] =
          (cart[key]!['paidQty'] ?? 0) + 1;
    });
  }

  void decreaseQty(String key) {
    setState(() {
      final currentQty =
          cart[key]!['paidQty'] ?? 0;

      if (currentQty > 1) {
        cart[key]!['paidQty'] = currentQty - 1;
      } else {
        cart.remove(key);
      }
    });
  }

  // ---------------- TOTAL ----------------

  double total() {
    double t = 0;

    for (var item in cart.values) {
      final price =
      (item['price'] ?? 0).toDouble();

      final qty =
      (item['paidQty'] ?? 0);

      final gst =
      (item['gst'] ?? 0).toDouble();

      final subtotal = price * qty;

      final gstAmount =
          subtotal * gst / 100;

      t += subtotal + gstAmount;
    }

    return t;
  }

  // ---------------- BACK TO PRODUCTS ----------------

  Future<bool> handleBack() async {
    if (widget.isEdit) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(

          builder: (_) => ShopDetailScreen(

            shopId: widget.shopId,
            shopName: widget.shopName,
            shopPhone: widget.shopPhone,
            shopAddress: widget.shopAddress,
            shopNote: widget.shopNote,
            existingCart: cart,
            editOrderId: widget.orderId,
            initialView: "products",
          ),
        ),
      );
    } else {
      Navigator.pop(context,cart);
    }
    return false;

  }

  @override
  Widget build(BuildContext context) {
    final grandTotal = total();

    return WillPopScope(
      onWillPop: handleBack,

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.isEdit
                ? "Edit Order Preview"
                : "Order Preview",
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back),

            onPressed: () async {
              await handleBack();
            },
          ),
        ),

        body: Column(
          children: [
            // ---------------- ITEMS ----------------

            Expanded(
              child: cart.isEmpty
                  ? const Center(
                child: Text(
                  "No items in order",
                ),
              )
                  : ListView(
                padding:
                const EdgeInsets.all(12),

                children:
                cart.entries.map((entry) {
                  final item =
                      entry.value;

                  final name =
                  item['name'];

                  final price =
                  (item['price'] ?? 0)
                      .toDouble();

                  final mrp =
                  (item['mrp'] ?? 0)
                      .toDouble();

                  final paidQty =
                      item['paidQty'] ?? 0;

                  final freeQty =
                      item['freeQty'] ?? 0;

                  final note =
                      item['note'] ?? "";

                  final itemTotal =
                      price * paidQty;

                  return Card(
                    margin:
                    const EdgeInsets.only(
                      bottom: 10,
                    ),

                    child: Padding(
                      padding:
                      const EdgeInsets.all(
                        12,
                      ),

                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment
                                .start,

                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                                  children: [
                                    Text(
                                      name,

                                      style:
                                      const TextStyle(
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        fontSize:
                                        16,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 6,
                                    ),

                                    Text(
                                      "Retail: ₹${price.toStringAsFixed(2)}",

                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .green,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    Text(
                                      "MRP: ₹${mrp.toStringAsFixed(2)}",

                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .grey,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      freeQty > 0
                                          ? "Qty: $paidQty + $freeQty FREE"
                                          : "Qty: $paidQty",
                                    ),
                                  ],
                                ),
                              ),

                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Quantity box
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove),
                                          onPressed: () {
                                            decreaseQty(entry.key);
                                          },
                                        ),
                                        Text(
                                          "$paidQty",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add),
                                          onPressed: () {
                                            increaseQty(entry.key);
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 10), // space between qty and delete

                                  // Delete button
                                  InkWell(
                                    onTap: () {
                                      setState(() {
                                        cart.remove(entry.key);
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),

                          if (note
                              .toString()
                              .trim()
                              .isNotEmpty)
                            Padding(
                              padding:
                              const EdgeInsets
                                  .only(
                                top: 8,
                              ),

                              child: Container(
                                width:
                                double.infinity,

                                padding:
                                const EdgeInsets
                                    .all(
                                  10,
                                ),

                                decoration:
                                BoxDecoration(
                                  color: Colors
                                      .orange
                                      .shade50,

                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    8,
                                  ),

                                  border:
                                  Border.all(
                                    color: Colors
                                        .orange
                                        .shade200,
                                  ),
                                ),

                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons
                                          .note_alt,
                                      color: Colors
                                          .orange,
                                      size: 18,
                                    ),

                                    const SizedBox(
                                      width: 8,
                                    ),

                                    Expanded(
                                      child:
                                      Text(
                                        note,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            "Total: ₹${itemTotal.toStringAsFixed(2)}",

                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // ---------------- BOTTOM ----------------

            SafeArea(
              top: false,

              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),

                decoration:
                const BoxDecoration(
                  color: Colors.white,

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 5,
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Total : ₹${grandTotal.toStringAsFixed(2)}",

                        style:
                        const TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    SizedBox(
                      height: 45,

                      child: ElevatedButton(
                        style:
                        ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF1565C0,
                          ),

                          foregroundColor:
                          Colors.white,
                        ),

                        onPressed: () async {
                          await placeOrder(
                            cart,
                            grandTotal,
                            editOrderId: widget.orderId,
                          );
                        },

                        child: Text(
                          widget.isEdit
                              ? "Update Order"
                              : "Confirm Order",

                          style:
                          const TextStyle(
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}