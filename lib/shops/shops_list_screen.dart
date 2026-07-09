import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_shop_screen.dart';
import 'shop_info_screen.dart';

class ShopsListScreen extends StatefulWidget {
  const ShopsListScreen({super.key});

  @override
  State<ShopsListScreen> createState() => _ShopsListScreenState();
}

class _ShopsListScreenState extends State<ShopsListScreen> {
  final shopsRef = FirebaseFirestore.instance.collection('shops');

  String search = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 🔍 SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search shops...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  search = val.toLowerCase();
                });
              },
            ),
          ),

          // 📦 SHOP LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: shopsRef.orderBy('name').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                final shops = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final name =
                  (data['name'] ?? '').toString().toLowerCase();

                  final address =
                  (data['address'] ?? '').toString().toLowerCase();

                  return name.contains(search) ||
                      address.contains(search);
                }).toList();

                if (shops.isEmpty) {
                  return const Center(child: Text("No Shops Found"));
                }

                return ListView.builder(
                  itemCount: shops.length,
                  itemBuilder: (context, index) {
                    final doc = shops[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1565C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.store,
                            color: Color(0xFF1565C0),
                          ),
                        ),
                        title: Text(
                          data['name'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(data['address'] ?? ''),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ShopInfoScreen(
                                shopId: doc.id,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      // ➕ ADD SHOP BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddShopScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}