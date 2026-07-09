import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'order_helpers.dart';
import 'order_details_screen.dart';
import 'package:untitled/shops/shop_detail_screen.dart';
import 'package:untitled/shops/order_preview_screen.dart';


class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ordersRef = FirebaseFirestore.instance.collection('orders');

  String selectedStatus = "all";
  String searchText = "";

  List<Map<String, dynamic>> allProducts = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('products').get();

    allProducts = snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data(),
      };
    }).toList();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: Column(
        children: [
          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search shop...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) {
                setState(() {
                  searchText = val.toLowerCase();
                });
              },
            ),
          ),

          // 🔘 FILTER
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ["all", "pending", "cancelled"].map((status) {
                final selected = selectedStatus == status;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(status.toUpperCase()),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        selectedStatus = status;
                      });
                    },
                    selectedColor: const Color(0xFF1565C0),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 10),

          // 📦 ORDERS LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              //stream: ordersRef.orderBy('createdAt', descending: true).snapshots(),
              stream: ordersRef.orderBy('updatedAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                var orders = snap.data!.docs;

                orders = orders.where((o) {
                  final status = o['status'];
                  final shop = o['shopName'].toString().toLowerCase();

                  return (selectedStatus == "all" ||
                      status == selectedStatus) &&
                      shop.contains(searchText);
                }).toList();

                if (orders.isEmpty) {
                  return const Center(child: Text("No Orders"));
                }

                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    final status = o['status'];

                    return InkWell(
                      borderRadius: BorderRadius.circular(14),

                      // ✅ OPEN ORDER DETAILS SCREEN
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) {
                              final data = o.data() as Map<String, dynamic>;

                              final List items = data['items'] ?? [];

                              final Map<String, Map<String, dynamic>> cart = {};

                              for (var item in items) {
                                final map =
                                Map<String, dynamic>.from(
                                    item);
                                final productId =
                                map['productId'].toString();

                                cart[productId] = {
                                  'productId': productId,
                                  'name': map['name'],
                                  'price': (map['price'] ?? 0).toDouble(),
                                  'mrp': (map['mrp'] ?? 0).toDouble(),
                                  'paidQty': map['paidQty'] ?? 0,
                                  'freeQty': map['freeQty'] ?? 0,
                                  'gst': (map['gst'] ?? 0)
                                      .toDouble(),
                                  'note': map['note'] ?? '',
                                };
                              }

                              return OrderDetailScreen(
                                //orderId: o.id,
                                shopName: data['shopName'] ?? '',
                                shopPhone: data['phone'] ?? '',
                                shopAddress: data['address'] ?? '',
                                status: data['status'] ?? '',
                               // total: (data['total'] ?? 0).toDouble(),
                                createdAt: data['createdAt'],
                                //note: data['note'] ?? '',
                                cart: cart,
                                //isEdit: true,

                              );
                            },
                          ),
                        );
                      },

                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 🔹 HEADER
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      o['shopName'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // 🔥 MENU
                                  PopupMenuButton(
                                    onSelected: (value) {
                                      if (value == 'pdf') {
                                        exportToPdf(
                                            o.data() as Map<String, dynamic>);
                                      } else if (value == 'edit') {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) {
                                              final items =
                                              List<Map<String, dynamic>>.from(
                                                o['items'] ?? [],
                                              );

                                              final Map<String,
                                                  Map<String, dynamic>>
                                              cart = {};

                                              for (var item in items) {
                                                final map =
                                                Map<String, dynamic>.from(
                                                    item);
                                                final productId =
                                                map['productId'].toString();

                                                cart[productId] = {
                                                  'productId': productId,
                                                  'name': map['name'],
                                                  'price':
                                                  (map['price'] ?? 0)
                                                      .toDouble(),
                                                  'mrp': (map['mrp'] ?? 0).toDouble(),
                                                  'paidQty': map['paidQty'] ?? 0,
                                                  'freeQty': map['freeQty'] ?? 0,
                                                  'gst': (map['gst'] ?? 0)
                                                      .toDouble(),
                                                  'note': map['note'] ?? '',
                                                };
                                              }

                                              return OrderPreviewScreen(
                                                cart: cart,

                                                isEdit: true,

                                                orderId: o.id,

                                                shopId: o['shopId'],
                                                shopName: o['shopName'],
                                                shopPhone: o['phone'],
                                                shopAddress: o['address'],
                                                shopNote: o['note'] ?? '',

                                              );
                                            },
                                          ),
                                        );
                                      }
                                      else if (value == 'delete') {
                                        showDialog(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("Delete Order"),
                                              content: const Text("Do you want to delete this order?"),
                                              actions: [
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1565C0),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context); // No
                                                  },
                                                  child: const Text(
                                                    "No",
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF1565C0),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    deleteOrder(o.id); // Yes
                                                  },
                                                  child: const Text(
                                                    "Yes",
                                                    style: TextStyle(color: Colors.white),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                          value: 'pdf',
                                          child: Text("Export PDF")),
                                      PopupMenuItem(
                                          value: 'edit',
                                          child: Text("Edit Order")),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // STATUS
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: getStatusColor(status),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  status.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 8),

                              Text(
                                //formatDate(o['createdAt']),
                                formatDate(o['updatedAt']),
                                style: const TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 6),

                              Text(
                                "Total: ₹ ${(o['total'] ?? 0).toDouble().toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ACTIONS
                              if (status == 'pending')
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF1565C0),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          markDelivered(context, o.id),
                                      child: const Text("Delivered"),
                                    ),
                                    const SizedBox(width: 10),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF1565C0),
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () => cancelOrder(o.id),
                                      child: const Text("Cancel"),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}