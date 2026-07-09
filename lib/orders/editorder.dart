import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shops/shop_detail_screen.dart';


class EditOrderScreen extends StatelessWidget {
  final QueryDocumentSnapshot order;

  const EditOrderScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    final items = List<Map<String, dynamic>>.from(order['items']);

    final Map<String, Map<String, dynamic>> cart = {};

    for (var item in items) {
      cart[item['productId']] = Map<String, dynamic>.from(item);
    }

    return ShopDetailScreen(
      shopId: order['shopId'],
      shopName: order['shopName'],
      shopPhone: order['phone'],
      shopAddress: order['address'],
      shopNote: order['note'],
      editOrderId: order.id,
      existingCart: cart,
    );
  }
}