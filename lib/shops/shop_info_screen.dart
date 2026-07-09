import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_detail_screen.dart';

class ShopInfoScreen extends StatefulWidget {
  final String shopId;

  const ShopInfoScreen({super.key, required this.shopId});

  @override
  State<ShopInfoScreen> createState() => _ShopInfoScreenState();
}

class _ShopInfoScreenState extends State<ShopInfoScreen> {
  DocumentReference get shopRef =>
      FirebaseFirestore.instance.collection('shops').doc(widget.shopId);

  // ❌ DELETE SHOP
  Future<void> deleteShop() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Delete"),
          content: const Text("Are you sure you want to delete this shop?"),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await shopRef.delete();

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Shop deleted"),
          backgroundColor: const Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"),
          backgroundColor:  Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ✏️ EDIT SHOP (NO LOCATION)
  void editShop(Map<String, dynamic> data) {
    final nameController =
    TextEditingController(text: data['name']);
    final addressController =
    TextEditingController(text: data['address']);
    final phoneController =
    TextEditingController(text: data['phone']);
    final noteController =
    TextEditingController(text: data['note'] ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Shop"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nameController,
                decoration:
                const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: addressController,
                decoration:
                const InputDecoration(labelText: "Address"),
              ),
              TextField(
                controller: phoneController,
                decoration:
                const InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: noteController,
                decoration:
                const InputDecoration(labelText: "Note"),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await shopRef.update({
                'name': nameController.text,
                'address': addressController.text,
                'phone': phoneController.text,
                'note': noteController.text,
              });

              Navigator.pop(context);
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Shop Info"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final doc = await shopRef.get();
              if (doc.exists) {
                editShop(doc.data() as Map<String, dynamic>);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: deleteShop,
          ),
        ],
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: shopRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Shop not found"));
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // 🏪 NAME
                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                // 📍 ADDRESS
                Text("📍 ${data['address'] ?? ''}"),

                const SizedBox(height: 10),

                // 📞 PHONE
                Text("📞 ${data['phone'] ?? ''}"),

                const SizedBox(height: 20),

                // 📝 NOTE
                const Text(
                  "Note",
                  style: TextStyle(
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border:
                    Border.all(color: Colors.grey),
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['note'] ?? "No note added",
                  ),
                ),
              ],
            ),
          );
        },
      ),

      // ➡️ GO TO PRODUCTS
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        child: const Icon(Icons.arrow_forward,color:Colors.white),
        onPressed: () async {
          final doc = await shopRef.get();

          if (!doc.exists) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ShopDetailScreen(
                shopId: widget.shopId,
                shopName: doc['name'],
                shopPhone: doc['phone'] ?? '',
                shopAddress: doc['address'] ?? '',
                shopNote: doc['note'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}