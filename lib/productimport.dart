import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> importProducts() async {
  final firestore = FirebaseFirestore.instance;

  print("🚀 STARTING PRODUCT IMPORT...");

  // ✅ LOAD JSON
  final String response =
  await rootBundle.loadString('assets/Products.json');

  final List data = json.decode(response);

  print("📦 TOTAL PRODUCTS: ${data.length}");

  int count = 0;

  for (var item in data) {

    // ✅ BRAND NAME
    final brandName = item['brand'] ?? '';

    // ✅ CATEGORY NAME
    final categoryName = item['categories'] ?? '';

    // 🔍 CHECK BRAND EXISTS
    final brandQuery = await firestore
        .collection('brands')
        .where('name', isEqualTo: brandName)
        .limit(1)
        .get();

    String brandId;

    // ✅ CREATE BRAND IF NOT EXISTS
    if (brandQuery.docs.isEmpty) {
      final brandDoc = await firestore.collection('brands').add({
        'name': brandName,
        'createdAt': Timestamp.now(),
      });

      brandId = brandDoc.id;

      print("✅ Brand Added: $brandName");
    } else {
      brandId = brandQuery.docs.first.id;
    }

    // 🔍 CHECK CATEGORY EXISTS
    final categoryQuery = await firestore
        .collection('brands')
        .doc(brandId)
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .limit(1)
        .get();

    String categoryId;

    // ✅ CREATE CATEGORY IF NOT EXISTS
    if (categoryQuery.docs.isEmpty) {
      final categoryDoc = await firestore
          .collection('brands')
          .doc(brandId)
          .collection('categories')
          .add({
        'name': categoryName,
        'createdAt': Timestamp.now(),
      });

      categoryId = categoryDoc.id;

      print("✅ Category Added: $categoryName");
    } else {
      categoryId = categoryQuery.docs.first.id;
    }

    // ✅ ADD PRODUCT INSIDE CATEGORY
    await firestore
        .collection('brands')
        .doc(brandId)
        .collection('categories')
        .doc(categoryId)
        .collection('products')
        .add({
      'name': item['name'] ?? '',
      'mrp': (item['mrp'] ?? 0).toDouble(),
      'retail': (item['retail'] ?? 0).toDouble(),
      'gst': (item['gst'] ?? 0).toDouble(),
      'image': item['image'] ?? '',
      'createdAt': Timestamp.now(),
    });

    count++;

    print("✅ Imported: $count / ${data.length}");
  }

  print("🎉 ALL PRODUCTS IMPORTED SUCCESSFULLY");
}