import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class ShopProductsView extends StatelessWidget {
  final String currentView;
  final String brandId;
  final String categoryId;
  final String search;
  final bool isGridView;
  // ✅ CART
  final Map<String, Map<String, dynamic>> cart;
  final Function(QueryDocumentSnapshot, Map<String, dynamic>)
  addToCart;

  final Function(String) removeFromCart;
  final Function(String) removeEntireProduct;
  final Function(String, String) onBrandSelect;

  final Function(String, String)
  onCategorySelect;

  const ShopProductsView({
    super.key,
    required this.currentView,
    required this.brandId,
    required this.categoryId,
    required this.search,
    required this.cart,
    required this.addToCart,
    required this.removeFromCart,
    required this.removeEntireProduct,
    required this.onBrandSelect,
    required this.onCategorySelect,
    required this.isGridView,
  });

  @override
  Widget build(BuildContext context) {
    return _mainView(context);
  }
  Widget _mainView(BuildContext context) {
    if (currentView == "brands") {
      if (search.isNotEmpty) {
        return _searchProducts(context); // 👈 NEW
      }
      return _brands();
    }

    if (currentView == "categories") {
      return _categories();
    }

    return _products(context);
  }
  Widget _searchProducts(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('products').snapshots(), // 🔥 all products
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.docs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(search);
        }).toList();

        if (data.isEmpty) {
          return const Center(child: Text("No products found"));
        }

        // ✅ SAME GRID UI (copied from your _products)
        return isGridView
            ? GridView.builder(
          padding: EdgeInsets.fromLTRB(
              10, 10, 10, cart.isNotEmpty ? 100 : 10),

          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemCount: data.length,

          itemBuilder: (_, i) {
            final doc = data[i];
            final d = doc.data() as Map<String, dynamic>;

            final id = doc.id;
            final name = d['name'] ?? '';
            final price = d['retail'] ?? 0;
            final mrp = d['mrp'] ?? 0;
            final image = d['image'] ?? '';

            final paid = cart[id]?['paidQty'] ?? 0;
            final free = cart[id]?['freeQty'] ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showFullImage(context, image),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: image.isNotEmpty
                            ? Image.network(image,
                            width: double.infinity,
                            fit: BoxFit.cover)
                            : const Center(child: Icon(Icons.image,size:50)),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                maxLines: 2,
                                softWrap: true,

                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),

                            GestureDetector(
                              onTap: () =>
                                  _showQtyDialog(context, doc),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1565C0),
                                  borderRadius:
                                  BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.add,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Retail: ₹$price",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              "MRP: ₹$mrp",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        if (paid > 0)
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(top: 4),

                            child: Text(
                              free > 0
                                  ? "$paid + $free FREE"
                                  : "Qty: $paid",

                              style:
                              const TextStyle(
                                color:
                                Colors.green,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        )
            : ListView.builder(
          padding: EdgeInsets.fromLTRB(
            10,
            10,
            10,
            cart.isNotEmpty ? 100 : 10,
          ),
          itemCount: data.length,
          itemBuilder: (_, i) {
            final doc = data[i];
            final d = doc.data() as Map<String, dynamic>;

            final id = doc.id;
            final name = d['name'] ?? '';
            final price = d['retail'] ?? 0;
            final mrp = d['mrp'] ?? 0;
            final image = d['image'] ?? '';

            final paid = cart[id]?['paidQty'] ?? 0;
            final free = cart[id]?['freeQty'] ?? 0;

            return Container(
              height: 110, // ✅ fix consistent height
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),

              child: Row(
                children: [
                  // 🔹 IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: image.isNotEmpty
                        ? GestureDetector(
                      onTap: () => _showFullImage(context, image),
                      child: Image.network(
                        image,
                        width: 100,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    )
                        : const Center(
                      child: Icon(
                        Icons.image,
                        size: 30,
                      ),
                    ),
                  ),

                  // 🔹 DETAILS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // ✅ spacing fix
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis, // ✅ fix overflow
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // 🔹 + BUTTON
                              GestureDetector(
                                onTap: () =>
                                    _showQtyDialog(context, doc),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Retail: ₹$price",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 14,
                                ),
                              ),

                              const SizedBox(height: 2),

                              Text(
                                "MRP: ₹$mrp",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),

                              if (paid > 0)
                                Padding(
                                  padding:
                                  const EdgeInsets.only(top: 2),
                                  child: Text(
                                    free > 0
                                        ? "$paid + $free FREE"
                                        : "Qty: $paid",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  // ---------------- BRANDS ----------------

  Widget _brands() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('brands')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snap.data!.docs
            .where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(search);
        })
            .toList()
          ..sort((a, b) {
            final aName = (a['name'] ?? '').toString().toLowerCase();
            final bName = (b['name'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });
        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) {
            final doc = data[i];

            final d =
            doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: d["image"].toString().isNotEmpty
                  ? Image.network(
                d["image"].toString(),
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.business,
                    color: Color(0xFF1565C0),
                    size: 25,
                  ),
                ),
              )
                  : const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.business,
                  color: Color(0xFF1565C0),
                  size: 25,
                ),
              ),

              title: Text(d["name"] ?? ""),

              trailing: const Icon(Icons.arrow_forward),

              onTap: () => onBrandSelect(
                doc.id,
                d["name"],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- CATEGORIES ----------------

  Widget _categories() {
    if (brandId.isEmpty) {
      return const Center(
        child: Text("Select a brand"),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('brands')
          .doc(brandId)
          .collection('categories')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snap.data!.docs
            .where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(search);
        })
            .toList()
          ..sort((a, b) {
            final aName = (a['name'] ?? '').toString().toLowerCase();
            final bName = (b['name'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });

        return ListView.builder(
          itemCount: data.length,
          itemBuilder: (_, i) {
            final doc = data[i];

            final d =
            doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: d["image"].toString().isNotEmpty
                  ? Image.network(
                d["image"].toString(),
                width: 40,
                height: 40,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.business,
                    color: Color(0xFF1565C0),
                    size: 25,
                  ),
                ),
              )
                  : const SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.business,
                  color: Color(0xFF1565C0),
                  size: 25,
                ),
              ),

              title: Text(d["name"] ?? ""),

              trailing: const Icon(Icons.arrow_forward),

              onTap: () => onCategorySelect(
                doc.id,
                d["name"],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- PRODUCTS ----------------

  Widget _products(BuildContext context) {
    if (brandId.isEmpty ||
        categoryId.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('brands')
          .doc(brandId)
          .collection('categories')
          .doc(categoryId)
          .collection('products')
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final data = snap.data!.docs
            .where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final name = (d['name'] ?? '').toString().toLowerCase();
          return name.contains(search);
        })
            .toList()
          ..sort((a, b) {
            final aName = (a['name'] ?? '').toString().toLowerCase();
            final bName = (b['name'] ?? '').toString().toLowerCase();
            return aName.compareTo(bName);
          });

        if (data.isEmpty) {
          return const Center(
            child: Text("No products found"),
          );
        }
        return isGridView
            ? GridView.builder(
          padding: EdgeInsets.fromLTRB(10, 10, 10, cart.isNotEmpty ? 100 : 10),

          gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),

          itemCount: data.length,

          itemBuilder: (_, i) {
            final doc = data[i];

            final d =
            doc.data() as Map<String, dynamic>;

            final id = doc.id;

            final name = d['name'] ?? '';

            final price = d['retail'] ?? 0;
            final mrp = d['mrp'] ?? 0;

            final image = d['image'] ?? '';

            final paid =
                cart[id]?['paidQty'] ?? 0;

            final free =
                cart[id]?['freeQty'] ?? 0;

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(12),

                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                  )
                ],
              ),

              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // 🔹 IMAGE
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          _showFullImage(
                            context,
                            image,
                          ),

                      child: ClipRRect(
                        borderRadius:
                        const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),

                        child: image.isNotEmpty
                            ? GestureDetector(
                          onTap: () => _showFullImage(context, image),
                          child: Image.network(
                            image,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                            : const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 🔹 DETAILS
                  Padding(
                    padding:
                    const EdgeInsets.all(8),

                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            Expanded(
                              child: Text(
                                name,

                                maxLines: 2,

                                softWrap: true,

                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            GestureDetector(
                              onTap: () =>
                                  _showQtyDialog(
                                    context,
                                    doc,
                                  ),

                              child: Container(
                                padding:
                                const EdgeInsets.all(5),

                                decoration:
                                BoxDecoration(
                                  color: const Color(
                                    0xFF1565C0,
                                  ),

                                  borderRadius:
                                  BorderRadius.circular(
                                      20),
                                ),

                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Retail: ₹$price",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 14,
                              ),
                            ),

                            const SizedBox(height: 2),

                            Text(
                              "MRP: ₹$mrp",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),

                        if (paid > 0)
                          Padding(
                            padding:
                            const EdgeInsets
                                .only(top: 4),

                            child: Text(
                              free > 0
                                  ? "$paid + $free FREE"
                                  : "Qty: $paid",

                              style:
                              const TextStyle(
                                color:
                                Colors.green,
                                fontWeight:
                                FontWeight
                                    .bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        )
            : ListView.builder(
          padding: EdgeInsets.fromLTRB(
            10,
            10,
            10,
            cart.isNotEmpty ? 100 : 10,
          ),
          itemCount: data.length,
          itemBuilder: (_, i) {
            final doc = data[i];
            final d = doc.data() as Map<String, dynamic>;

            final id = doc.id;
            final name = d['name'] ?? '';
            final price = d['retail'] ?? 0;
            final mrp = d['mrp'] ?? 0;
            final image = d['image'] ?? '';

            final paid = cart[id]?['paidQty'] ?? 0;
            final free = cart[id]?['freeQty'] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5)
                ],
              ),

              child: Row(
                children: [
                  // 🔹 IMAGE
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                    child: image.isNotEmpty
                        ? GestureDetector(
                      onTap: () => _showFullImage(context, image),
                      child: Image.network(
                        image,
                        width: 100,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
                    )
                : const Center(
            child: Icon(
            Icons.image,
            size: 35,
            ),),
                  ),

                  // 🔹 DETAILS
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  maxLines: 2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 6),

                              // 🔹 SAME + BUTTON
                              GestureDetector(
                                onTap: () =>
                                    _showQtyDialog(context, doc),
                                child: Container(
                                  padding:
                                  const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          Text(
                            "Retail: ₹$price",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            "MRP: ₹$mrp",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),

                          if (paid > 0)
                            Padding(
                              padding:
                              const EdgeInsets.only(top: 4),
                              child: Text(
                                free > 0
                                    ? "$paid + $free FREE"
                                    : "Qty: $paid",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- FULL IMAGE ----------------

  void _showFullImage(
      BuildContext context,
      String image,
      ) {
    if (image.isEmpty) return;

    showDialog(
      context: context,

      builder: (_) => Dialog(
        backgroundColor: Colors.black,

        insetPadding:
        const EdgeInsets.all(10),

        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                image,
                fit: BoxFit.contain,
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.black,
                ),

                onPressed: () =>
                    Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- QTY DIALOG ----------------
  void _showQtyDialog(
      BuildContext context,
      QueryDocumentSnapshot doc,
      ) {
    final data = doc.data() as Map<String, dynamic>;

    // ✅ GET EXISTING CART VALUE
    final existing = cart[doc.id];

    TextEditingController qtyController = TextEditingController(
      text: existing != null
          ? "${existing['paidQty'] ?? 0}"
          : "",
    );

    TextEditingController noteController =
    TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              data['name'] ?? '',
            ),

            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 QTY FIELD (UNCHANGED UI)
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    hintText: "Enter qty (e.g. 5 or 5+1)",
                  ),
                ),

                const SizedBox(height: 15),

                // 🔹 NOTE BUTTON (UNCHANGED UI)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Product Note"),
                        content: TextField(
                          controller: noteController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: "Enter note or number...",
                          ),
                        ),
                        actions: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              setState(() {});
                            },
                            child: const Text("Done"),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.note_alt),
                  label: Text(
                    noteController.text.isEmpty
                        ? "Add Note"
                        : "Edit Note",
                  ),
                ),

                // 🔹 NOTE PREVIEW (UNCHANGED UI)
                if (noteController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Note",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(noteController.text),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (existing != null)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 28,
                      ),
                      tooltip: "Remove from Cart",
                      onPressed: () {
                        removeEntireProduct(doc.id);
                        Navigator.pop(context);
                      },
                    )
                  else
                    const SizedBox(width: 48),

                  Row(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),

                      const SizedBox(width: 8),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1565C0),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final qtyData = _parseQty(qtyController.text);

                          qtyData["note"] = noteController.text.trim();

                          if (qtyData["total"] == 0) {
                            removeFromCart(doc.id);
                          } else {
                            addToCart(doc, qtyData);
                          }

                          Navigator.pop(context);
                        },
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- PARSE QTY ----------------

  Map<String, dynamic> _parseQty(
      String input) {
    try {
      final parts = input.split('+');

      int paid =
      int.parse(parts[0].trim());

      int free = 0;

      if (parts.length > 1) {
        free =
            int.parse(parts[1].trim());
      }

      return {
        "paid": paid,
        "free": free,
        "total": paid + free,
      };
    } catch (e) {
      int val =
          int.tryParse(input) ?? 0;

      return {
        "paid": val,
        "free": 0,
        "total": val,
      };
    }
  }
}