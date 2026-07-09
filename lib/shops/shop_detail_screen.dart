import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_products_view.dart';
import 'cart_bar.dart';
import 'order_preview_screen.dart';

class ShopDetailScreen extends StatefulWidget {
  final String shopId;
  final String shopName;
  final String shopPhone;
  final String shopAddress;
  final String shopNote;

  // ✅ EDIT MODE CART
  final Map<String, Map<String, dynamic>>? existingCart;

  // ✅ FIX: INITIAL VIEW FOR EDIT MODE
  final String? initialView;
  final String? editOrderId;

  const ShopDetailScreen({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.shopPhone,
    required this.shopAddress,
    required this.shopNote,
    this.existingCart,
    this.initialView,
    this.editOrderId,
  });

  @override
  State<ShopDetailScreen> createState() => _ShopDetailScreenState();
}

class _ShopDetailScreenState extends State<ShopDetailScreen> {
  String currentView = "brands";

  String brandId = "";
  String brandName = "";

  String categoryId = "";
  String categoryName = "";
  bool isGridView = true;
  String search = '';

  final TextEditingController noteController = TextEditingController();

  // 🛒 CART
  Map<String, Map<String, dynamic>> cart = {};

  @override
  void initState() {
    super.initState();

    if (widget.existingCart != null) {
      cart = Map<String, Map<String, dynamic>>.from(widget.existingCart!);
    }

    // ✅ ALWAYS START FROM BRANDS (FIX)
    currentView = "brands";
  }

  // ---------------- CART ----------------

  void addToCart(
      QueryDocumentSnapshot p,
      Map<String, dynamic> qtyData,
      ) {
    final data = p.data() as Map<String, dynamic>;
    final id = p.id;

    final name = data['name'] ?? 'No Name';
    final price = (data['retail'] ?? 0).toDouble();
    final gst = (data['gst'] ?? 0).toDouble();
    final mrp = (data['mrp'] ?? 0).toDouble();
    final paid = qtyData["paid"] ?? 0;
    final free = qtyData["free"] ?? 0;
    final note = qtyData["note"] ?? "";

    // ✅ REPLACE MODE (NOT ADD)
    cart[id] = {
      'productId': id,
      'name': name,
      'price': price,
      'mrp': mrp,
      'gst': gst,
      'paidQty': paid,
      'freeQty': free,
      'note': note,
    };

    setState(() {});
  }
  void removeEntireProduct(String id) {
    cart.remove(id);
    setState(() {});
  }
  void removeFromCart(String id) {
    if (!cart.containsKey(id)) return;

    final qty = cart[id]!['paidQty'] ?? 0;

    if (qty > 1) {
      cart[id]!['paidQty'] = qty - 1;
    } else {
      cart.remove(id);
    }

    setState(() {});
  }

  // ---------------- TOTAL ----------------

  double total() {
    double t = 0;

    for (var item in cart.values) {
      final price = (item['price'] ?? 0).toDouble();
      final qty = item['paidQty'] ?? 0;
      final gst = (item['gst'] ?? 0).toDouble();

      final subtotal = price * qty;
      final gstAmount = subtotal * gst / 100;

      t += subtotal + gstAmount;
    }

    return t;
  }

  // ---------------- ORDER ----------------

  // ---------------- NAVIGATION ----------------

  void selectBrand(String id, String name) {
    setState(() {
      currentView = "categories";
      brandId = id;
      brandName = name;
      categoryId = "";
      search = '';
    });
  }

  void selectCategory(String id, String name) {
    setState(() {
      currentView = "products";
      categoryId = id;
      categoryName = name;
      search = '';
    });
  }

  void goBack() {
    setState(() {
      if (currentView == "products") {
        currentView = "categories";
      } else if (currentView == "categories") {
        currentView = "brands";
      }
      search = '';
    });
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {

        if (currentView == "products") {
          setState(() {
            currentView = "categories";
          });
          return false;
        }

        if (currentView == "categories") {
          setState(() {
            currentView = "brands";
            brandId = "";
            categoryId = "";
          });
          return false;
        }

        if (currentView == "brands") {
          if (cart.isNotEmpty) {
            final confirm = await showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text("Discard Order"),
                content: const Text(
                  "You have items in cart. Do you want to go back?",
                ),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("No"),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );

            return confirm ?? false;
          }

          return true;
        }

        return true; // ✅ IMPORTANT FIX
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            currentView == "brands"
                ? widget.shopName
                : currentView == "categories"
                ? brandName
                : categoryName,
          ),
          leading: currentView == "brands"
              ? null
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: goBack,
          ),
        ),

        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
              child: Row(
                children: [
                  // 🔹 SEARCH
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (v) => setState(() {
                        search = v.toLowerCase();
                      }),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // 🔹 TOGGLE BUTTON
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        isGridView ? Icons.list : Icons.grid_view,
                        size: 22,
                      ),
                      onPressed: () {
                        setState(() {
                          isGridView = !isGridView;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ShopProductsView(
                currentView: currentView,
                brandId: brandId,
                categoryId: categoryId,
                search: search,

                cart: cart,
                addToCart: addToCart,
                removeFromCart: removeFromCart,
                removeEntireProduct:removeEntireProduct,
                onBrandSelect: selectBrand,
                onCategorySelect: selectCategory,
                isGridView: isGridView,
              ),
            ),

            if (cart.isNotEmpty)
              SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total : ₹${total().toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final updatedCart = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderPreviewScreen(
                                cart: cart,
                                isEdit: widget.editOrderId != null,
                                orderId: widget.editOrderId,
                                shopId: widget.shopId,
                                shopName: widget.shopName,
                                shopPhone: widget.shopPhone,
                                shopAddress: widget.shopAddress,
                                shopNote: widget.shopNote,

                              ),
                            ),
                          );

                          if (updatedCart != null) {
                            setState(() {
                              cart = Map<String, Map<String, dynamic>>.from(updatedCart);
                            });
                          }
                        },
                        child: const Text("Place Order"),
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