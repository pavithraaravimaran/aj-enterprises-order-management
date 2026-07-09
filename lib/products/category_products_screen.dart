import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/products/product_detail_screen.dart';
import 'add_product_screen.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:image_picker/image_picker.dart';

import 'dart:io';
class CategoryProductsScreen extends StatefulWidget {
  final String brandId;
  final String categoryId;
  final String categoryName;
  final String categoryImage;
  const CategoryProductsScreen({
    super.key,
    required this.brandId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
  });

  @override
  State<CategoryProductsScreen> createState() =>
      _CategoryProductsScreenState();
}

class _CategoryProductsScreenState
    extends State<CategoryProductsScreen> {

  final searchController = TextEditingController();
  String searchText = '';

  // ================= NEW: SELECTION SYSTEM =================
  bool selectionMode = false;
  Set<String> selectedProducts = {};

  DocumentReference get categoryRef =>
      FirebaseFirestore.instance
          .collection('brands')
          .doc(widget.brandId)
          .collection('categories')
          .doc(widget.categoryId);

  // =========================================================

  @override
  Widget build(BuildContext context) {
    final ref = categoryRef.collection('products');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        backgroundColor: const Color(0xFF1565C0),

        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'select') {
                setState(() {
                  selectionMode = true;
                });
              } else if (value == 'move') {
                _showMoveBottomSheet();
              } else if (value == 'edit') {
                editCategory();
              } else if (value == 'delete') {
                deleteCategory();
              }
            },
            itemBuilder: (context) => const [

              // ✏️ EDIT
              PopupMenuItem(
                value: 'edit',

                child: Row(
                  children: [

                    Icon(
                      Icons.edit,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text("Edit Category"),
                  ],
                ),
              ),

              // ❌ DELETE
              PopupMenuItem(
                value: 'delete',

                child: Row(
                  children: [

                    Icon(
                      Icons.delete,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text("Delete Category"),
                  ],
                ),
              ),

              // ✅ SELECT
              PopupMenuItem(
                value: 'select',

                child: Row(
                  children: [

                    Icon(
                      Icons.check_box,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text("Select Products"),
                  ],
                ),
              ),

              // 🚚 MOVE
              PopupMenuItem(
                value: 'move',

                child: Row(
                  children: [

                    Icon(
                      Icons.drive_file_move,
                      color: Color(0xFF1565C0),
                      size: 18,
                    ),

                    SizedBox(width: 8),

                    Text("Move Products"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Column(
        children: [

          // 🔍 SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => searchText = val.toLowerCase()),
            ),
          ),

          // 📦 PRODUCT LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!.docs.where((p) {
                  final name = (p['name'] ?? '').toString().toLowerCase();
                  return name.contains(searchText);
                }).toList()
                  ..sort((a, b) {
                    final nameA = (a['name'] ?? '').toString().toLowerCase();
                    final nameB = (b['name'] ?? '').toString().toLowerCase();
                    return nameA.compareTo(nameB);
                  });

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final p = data[index];
                    final d = p.data() as Map<String, dynamic>;
                    final image = d['image'] ?? '';
                    final isSelected = selectedProducts.contains(p.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),

                      child: ListTile(

                        leading: image.toString().isNotEmpty
                            ? Image.network(
                          image,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            width: 50,
                            height: 50,
                            child: Center(
                              child: Icon(
                                Icons.image,
                                size: 25,
                              ),
                            ),
                          ),
                        )
                            : const SizedBox(
                          width: 50,
                          height: 50,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 25,
                            ),
                          ),
                        ),

                        title: Text(d['name'] ?? ''),

                        subtitle: Text(
                            "₹${d['mrp'] ?? 0} → ₹${d['retail'] ?? 0}"),

                        trailing: selectionMode
                            ? Checkbox(
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                selectedProducts.add(p.id);
                              } else {
                                selectedProducts.remove(p.id);
                              }
                            });
                          },
                        )
                            : null,

                        onLongPress: () {
                          setState(() {
                            selectionMode = true;
                            selectedProducts.add(p.id);
                          });
                        },

                        onTap: () {
                          if (selectionMode) {
                            setState(() {
                              if (isSelected) {
                                selectedProducts.remove(p.id);
                              } else {
                                selectedProducts.add(p.id);
                              }
                            });
                            return;
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                brandId: widget.brandId,
                                categoryId: widget.categoryId,
                                productId: p.id,
                                productData: d,
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

      // ➕ ADD PRODUCT
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductScreen(
                brandId: widget.brandId,
                categoryId: widget.categoryId,
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  Future<String> uploadToCloudinary(File file) async {
    const cloudName = "drft8otdg";
    const uploadPreset = "aj_enterprises";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
    );

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    final response = await request.send();
    final resStr = await response.stream.bytesToString();
    final data = json.decode(resStr);

    if (response.statusCode == 200) {
      return data['secure_url'];
    } else {
      throw Exception("Image upload failed");
    }
  }
  // ================= MOVE PRODUCTS (CLEAN UI) =================

  void _showMoveBottomSheet() {
    if (selectedProducts.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Wrap(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: Text(
                  "Move Products",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Move to Existing Category"),
              onTap: () {
                Navigator.pop(context);
                _pickExistingCategory();
              },
            ),

            ListTile(
              leading: const Icon(Icons.add),
              title: const Text("Move to New Category"),
              onTap: () {
                Navigator.pop(context);
                _createNewCategory();
              },
            ),
          ],
        );
      },
    );
  }

  // ================= EXISTING CATEGORY =================

  Future<void> _pickExistingCategory() async {
    final snap = await FirebaseFirestore.instance
        .collection('brands')
        .doc(widget.brandId)
        .collection('categories')
        .get();

    String? target;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        final filtered = snap.docs
            .where((c) => c.id != widget.categoryId)
            .toList();

        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisSize: MainAxisSize.min, // 🔥 HALF BOTTOM SHEET

                children: [

                  const SizedBox(height: 8),

                  // 🔵 SMALL HANDLE BAR (like real bottom sheet)
                  Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "Select Category",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📦 BOX CATEGORY LIST
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final c = filtered[index];

                        return GestureDetector(
                          onTap: () {
                            target = c.id;
                            Navigator.pop(context);
                          },

                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 6),

                            padding: const EdgeInsets.all(12),

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),

                              border: Border.all(
                                color: Colors.grey.shade300,
                              ),

                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 3,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),

                            child: Row(
                              children: [

                                // 🔵 ICON BOX
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1565C0),
                                    borderRadius:
                                    BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.category,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // 📝 NAME
                                Expanded(
                                  child: Text(
                                    c['name'],
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (target == null) return;

    await _moveProducts(target!);
  }
  // ================= NEW CATEGORY =================

  Future<void> _createNewCategory() async {
    final controller = TextEditingController();
    String? newId;
    String? errorText;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("New Category"),

            content: TextField(
              controller: controller,
              autofocus: true,

              decoration: InputDecoration(
                hintText: "Enter category name",
                errorText: errorText, // 🔥 INLINE VALIDATION
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
                  final name = controller.text.trim();

                  // 🔴 FIELD VALIDATION (NO SNACKBAR)
                  if (name.isEmpty) {
                    setState(() {
                      errorText = "Category name is required";
                    });
                    return;
                  }

                  final doc = await FirebaseFirestore.instance
                      .collection('brands')
                      .doc(widget.brandId)
                      .collection('categories')
                      .add({
                    'name': name,
                    'createdAt': Timestamp.now(),
                  });

                  newId = doc.id;
                  Navigator.pop(context);
                },
                child: const Text("Create"),
              ),
            ],
          );
        },
      ),
    );

    if (newId == null) return;

    await _moveProducts(newId!);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Category created & products moved"),
        backgroundColor: Color(0xFF1565C0),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),

      ),
    );
  }

  // ================= MOVE LOGIC =================

  Future<void> _moveProducts(String targetCategoryId) async {
    if (selectedProducts.isEmpty) return;

    // 🔵 LOADING DIALOG
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
              color: Color(0xFF1565C0),
            ),
            SizedBox(width: 20),
            Expanded(child: Text("Moving products...")),
          ],
        ),
      ),
    );

    try {
      int total = selectedProducts.length;
      int moved = 0;

      for (String id in List.from(selectedProducts)) {
        final oldDoc = categoryRef.collection('products').doc(id);
        final snap = await oldDoc.get();

        if (snap.exists) {
          final data = snap.data() as Map<String, dynamic>;

          // ✅ 1. COPY TO NEW CATEGORY
          await FirebaseFirestore.instance
              .collection('brands')
              .doc(widget.brandId)
              .collection('categories')
              .doc(targetCategoryId)
              .collection('products')
              .doc(id)
              .set(data);

          // ✅ 2. DELETE FROM CURRENT CATEGORY (ONLY AFTER SUCCESS)
          await oldDoc.delete();

          // remove locally also
          selectedProducts.remove(id);
          moved++;
        }
      }

      Navigator.pop(context); // close loading

      setState(() {
        selectionMode = false;
        selectedProducts.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Moved $moved / $total products successfully"),
          backgroundColor: const Color(0xFF1565C0),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error moving products: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  // ================= EXISTING FUNCTIONS (UNCHANGED) =================

  // ✏️ EDIT CATEGORY
  void editCategory() {
    final controller =
    TextEditingController(text: widget.categoryName);

    File? newImage;
    String imageUrl = widget.categoryImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Category"),

            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Category Image
                  Stack(
                    clipBehavior: Clip.none,
                    children: [

                      GestureDetector(
                        onTap: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );

                          if (picked != null) {
                            setDialogState(() {
                              newImage = File(picked.path);
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: newImage != null
                              ? FileImage(newImage!)
                              : (imageUrl.isNotEmpty
                              ? NetworkImage(imageUrl)
                              : null) as ImageProvider?,
                          child: newImage == null && imageUrl.isEmpty
                              ? const Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: Colors.grey,
                          )
                              : null,
                        ),
                      ),

                      /// Delete Image
                      if (newImage != null || imageUrl.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title:
                                  const Text("Remove Image"),
                                  content: const Text(
                                    "Are you sure you want to remove this image?",
                                  ),
                                  actions: [

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        const Color(0xFF1565C0),
                                        foregroundColor:
                                        Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, false),
                                      child:
                                      const Text("Cancel"),
                                    ),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                        Colors.red,
                                        foregroundColor:
                                        Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(
                                              context, true),
                                      child:
                                      const Text("Remove"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                setDialogState(() {
                                  newImage = null;
                                  imageUrl = "";
                                });
                              }
                            },
                            child: Container(
                              padding:
                              const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Enter category name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),

            actions: [

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                onPressed: () =>
                    Navigator.pop(context),
                child: const Text("Cancel"),
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (controller.text.trim().isEmpty) return;

                  String finalImage = imageUrl;

                  if (newImage != null) {
                    finalImage =
                    await uploadToCloudinary(newImage!);
                  }

                  await categoryRef.update({
                    "name": controller.text.trim(),
                    "image": finalImage,
                  });

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content:
                      Text("Category updated"),
                      duration: Duration(seconds: 2),
                      behavior:
                      SnackBarBehavior.floating,
                      backgroundColor:
                      Color(0xFF1565C0),
                    ),
                  );
                },
                child: const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  // ❌ DELETE CATEGORY
  void deleteCategory() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content: const Text(
            "This will delete the category. Continue?"),

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
              backgroundColor: Color(0xFF1565C0),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await categoryRef.delete();

              if (!mounted) return;

              Navigator.pop(context); // dialog
              Navigator.pop(context); // back

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Category deleted"),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF1565C0),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}