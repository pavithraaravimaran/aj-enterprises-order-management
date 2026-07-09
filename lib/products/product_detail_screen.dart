import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_product_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String brandId;
  final String categoryId;
  final String productId;
  final Map<String, dynamic> productData;

  const ProductDetailScreen({
    super.key,
    required this.brandId,
    required this.categoryId,
    required this.productId,
    required this.productData,
  });

  // 🖼️ FULL SCREEN IMAGE VIEW
  void showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // ❌ CLOSE BUTTON
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = FirebaseFirestore.instance
        .collection('brands')
        .doc(brandId)
        .collection('categories')
        .doc(categoryId)
        .collection('products')
        .doc(productId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: [
          // ✏️ EDIT
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductScreen(
                    brandId: brandId,
                    categoryId: categoryId,
                    productId: productId,
                    existingData: productData,
                  ),
                ),
              );

              // ✅ SHOW ONLY IF ACTUAL UPDATE DONE
              if (result == true) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Product updated successfully"),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),

          // 🗑 DELETE
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Delete Product"),
                  content: const Text(
                    "Are you sure you want to delete this product?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Delete"),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.delete();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("🗑 Product deleted successfully"),
                    backgroundColor: Colors.red,
                  ),
                );

                Navigator.pop(context);
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            productData['image'] != null && productData['image'] != ''
                ? GestureDetector(
              onTap: () {
                showFullImage(context, productData['image']);
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  productData['image'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            )
                : Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.image, size: 50),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              productData['name'] ?? 'No Name',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              "MRP: ₹${productData['mrp'] ?? 0}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 8),

            Text(
              "Retail: ₹${productData['retail'] ?? 0}",
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              "GST: ${productData['gst'] ?? 0}%",
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFEF6C00),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}