import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'category_products_screen.dart';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
class CategoriesScreen extends StatefulWidget {
  final String brandId;
  final String brandName;
  final String brandImage;
  const CategoriesScreen({
    super.key,
    required this.brandId,
    required this.brandName,
    required this.brandImage,
  });

  @override
  State<CategoriesScreen> createState() =>
      _CategoriesScreenState();
}

class _CategoriesScreenState
    extends State<CategoriesScreen> {

  final TextEditingController controller =
  TextEditingController();

  final TextEditingController searchController =
  TextEditingController();
  File? imageFile;
  String searchText = '';

  // ✅ CATEGORY SELECTION
  bool selectionMode = false;

  Set<String> selectedCategories = {};

  // 🔹 BRAND REF
  DocumentReference get brandRef =>
      FirebaseFirestore.instance
          .collection('brands')
          .doc(widget.brandId);

  Future<String> uploadToCloudinary(File file) async {
    const cloudName = "drft8otdg";
    const uploadPreset = "aj_enterprises";

    final url = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload");

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
  // =========================================================
  // ✏️ EDIT BRAND
  // =========================================================

  void editBrand() {
    final editController = TextEditingController(text: widget.brandName);

    File? newImage;
    String imageUrl = widget.brandImage;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Brand"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Brand Image
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

                      /// Delete Button
                      if (newImage != null || imageUrl.isNotEmpty)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Remove Image"),
                                  content: const Text(
                                    "Are you sure you want to remove this image?",
                                  ),
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
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Remove"),
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
                              padding: const EdgeInsets.all(4),
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
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: editController,
                    decoration: const InputDecoration(
                      labelText: "Brand Name",
                      border: OutlineInputBorder(),
                    ),
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
                  if (editController.text.trim().isEmpty) return;

                  String finalImage = imageUrl;

                  if (newImage != null) {
                    finalImage = await uploadToCloudinary(newImage!);
                  }

                  await brandRef.update({
                    "name": editController.text.trim(),
                    "image": finalImage,
                  });

                  if (!mounted) return;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Brand updated successfully"),
                      backgroundColor: Color(0xFF1565C0),
                      behavior: SnackBarBehavior.floating,
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
  // =========================================================
  // ❌ DELETE BRAND
  // =========================================================

  void deleteBrand() {

    showDialog(
      context: context,

      builder: (_) => AlertDialog(

        title: const Text("Delete Brand"),

        content: const Text(
          "This will delete the brand and categories. Continue?",
        ),

        actions: [

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF1565C0),
            ),

            onPressed: () =>
                Navigator.pop(context),

            child: const Text(
              "Cancel",
              style: TextStyle(
                  color: Colors.white),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF1565C0),
            ),

            onPressed: () async {

              await brandRef.delete();

              if (!mounted) return;

              Navigator.pop(context);
              Navigator.pop(context);

              ScaffoldMessenger.of(context)
                  .showSnackBar(
                const SnackBar(
                  content:
                  Text("Brand deleted"),
                  backgroundColor:
                  Color(0xFF1565C0),
                  behavior:
                  SnackBarBehavior.floating,
                ),
              );
            },

            child: const Text(
              "Delete",
              style: TextStyle(
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // 🚚 MOVE OPTIONS
  // =========================================================

  void _showMoveBottomSheet() {

    if (selectedCategories.isEmpty) return;

    showModalBottomSheet(

      context: context,

      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (_) {

        return Wrap(
          children: [

            const Padding(
              padding: EdgeInsets.all(16),

              child: Center(
                child: Text(
                  "Move Categories",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            ListTile(

              leading:
              const Icon(Icons.business),

              title:
              const Text("Move to Existing Brand"),

              onTap: () {

                Navigator.pop(context);

                _pickExistingBrand();
              },
            ),

            ListTile(

              leading:
              const Icon(Icons.add_business),

              title:
              const Text("Move to New Brand"),

              onTap: () {

                Navigator.pop(context);

                _createNewBrand();
              },
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // 🏢 EXISTING BRAND
  // =========================================================

  Future<void> _pickExistingBrand() async {

    final snap = await FirebaseFirestore.instance
        .collection('brands')
        .get();

    String? targetBrandId;

    await showModalBottomSheet(

      context: context,

      isScrollControlled: true,

      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (_) {

        final brands = snap.docs
            .where((b) => b.id != widget.brandId)
            .toList();

        return SizedBox(

          height: MediaQuery.of(context).size.height * 0.55,

          child: Padding(
            padding: const EdgeInsets.all(12),

            child: Column(
              children: [

                const SizedBox(height: 8),

                // 🔘 HANDLE
                Container(
                  width: 40,
                  height: 5,

                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 14),

                const Text(
                  "Select Brand",

                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),

                const SizedBox(height: 14),

                // 📦 BRAND LIST
                Expanded(
                  child: ListView.builder(

                    itemCount: brands.length,

                    itemBuilder: (context, index) {

                      final b = brands[index];

                      return GestureDetector(

                        onTap: () async {

                          targetBrandId = b.id;

                          Navigator.pop(context);

                          await _moveCategories(
                              targetBrandId!);
                        },

                        child: Container(

                          margin:
                          const EdgeInsets.symmetric(
                              vertical: 6),

                          padding:
                          const EdgeInsets.all(12),

                          decoration: BoxDecoration(

                            color: Colors.white,

                            borderRadius:
                            BorderRadius.circular(12),

                            border: Border.all(
                              color:
                              Colors.grey.shade300,
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

                              Container(
                                padding:
                                const EdgeInsets.all(8),

                                decoration: BoxDecoration(
                                  color:
                                  const Color(0xFF1565C0),

                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),

                                child: const Icon(
                                  Icons.business,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  b['name'],

                                  style:
                                  const TextStyle(
                                    fontSize: 15,
                                    fontWeight:
                                    FontWeight.w500,
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
          ),
        );
      },
    );
  }

  // =========================================================
  // ➕ NEW BRAND
  // =========================================================

  Future<void> _createNewBrand() async {

    final brandController =
    TextEditingController();

    String? newBrandId;

    await showDialog(

      context: context,

      builder: (_) => AlertDialog(

        title: const Text("New Brand"),

        content: TextField(
          controller: brandController,

          decoration: const InputDecoration(
            hintText: "Enter brand name",
            border: OutlineInputBorder(),
          ),
        ),

        actions: [

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF1565C0),
            ),

            onPressed: () =>
                Navigator.pop(context),

            child: const Text(
              "Cancel",
              style: TextStyle(
                  color: Colors.white),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFF1565C0),
            ),

            onPressed: () async {

              if (brandController.text
                  .trim()
                  .isEmpty) return;

              final doc =
              await FirebaseFirestore.instance
                  .collection('brands')
                  .add({

                'name':
                brandController.text.trim(),

                'createdAt':
                Timestamp.now(),
              });

              newBrandId = doc.id;

              Navigator.pop(context);
            },

            child: const Text(
              "Create",
              style: TextStyle(
                  color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (newBrandId == null) return;

    await _moveCategories(newBrandId!);
  }

  // =========================================================
  // 🔄 MOVE LOGIC
  // =========================================================

  Future<void> _moveCategories(
      String targetBrandId,
      ) async {

    try {

      for (String categoryId in selectedCategories) {

        // OLD CATEGORY REF
        final oldCategoryRef = FirebaseFirestore.instance
            .collection('brands')
            .doc(widget.brandId)
            .collection('categories')
            .doc(categoryId);

        // GET CATEGORY DATA
        final categorySnap =
        await oldCategoryRef.get();

        if (!categorySnap.exists) continue;

        final categoryData =
        categorySnap.data()
        as Map<String, dynamic>;

        // NEW CATEGORY REF
        final newCategoryRef = FirebaseFirestore.instance
            .collection('brands')
            .doc(targetBrandId)
            .collection('categories')
            .doc(categoryId);

        // ✅ CREATE CATEGORY
        await newCategoryRef.set(categoryData);

        // =================================================
        // ✅ MOVE PRODUCTS INSIDE CATEGORY
        // =================================================

        final productsSnap =
        await oldCategoryRef
            .collection('products')
            .get();

        for (var product in productsSnap.docs) {

          final productData = product.data();

          // COPY PRODUCT
          await newCategoryRef
              .collection('products')
              .doc(product.id)
              .set(productData);

          // DELETE OLD PRODUCT
          await oldCategoryRef
              .collection('products')
              .doc(product.id)
              .delete();
        }

        // =================================================
        // ✅ DELETE OLD CATEGORY
        // =================================================

        await oldCategoryRef.delete();
      }

      setState(() {

        selectionMode = false;

        selectedCategories.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content:
          Text("Categories moved successfully"),

          backgroundColor:
          Color(0xFF1565C0),

          behavior:
          SnackBarBehavior.floating,
        ),
      );

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content:
          Text("Error: $e"),
          behavior:
          SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // UI
  // =========================================================

  @override
  Widget build(BuildContext context) {

    final ref = FirebaseFirestore.instance
        .collection('brands')
        .doc(widget.brandId)
        .collection('categories');

    return Scaffold(

      appBar: AppBar(

        title: Text(widget.brandName),

        backgroundColor:
        const Color(0xFF1565C0),

        actions: [

          PopupMenuButton<String>(

            onSelected: (value) {

              if (value == 'edit') {
                editBrand();
              }

              else if (value == 'delete') {
                deleteBrand();
              }

              else if (value == 'select') {

                setState(() {
                  selectionMode = true;
                });
              }

              else if (value == 'move') {
                _showMoveBottomSheet();
              }
            },

            itemBuilder: (context) => [

              const PopupMenuItem(
                value: 'edit',

                child: Row(
                  children: [

                    Icon(Icons.edit,
                        color: Color(0xFF1565C0),
                        size: 18),

                    SizedBox(width: 8),

                    Text("Edit Brand"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'delete',

                child: Row(
                  children: [

                    Icon(Icons.delete,
                        color: Color(0xFF1565C0),
                        size: 18),

                    SizedBox(width: 8),

                    Text("Delete Brand"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'select',

                child: Row(
                  children: [

                    Icon(Icons.check_box,
                        color: Color(0xFF1565C0),
                        size: 18),

                    SizedBox(width: 8),

                    Text("Select Categories"),
                  ],
                ),
              ),

              const PopupMenuItem(
                value: 'move',

                child: Row(
                  children: [

                    Icon(Icons.drive_file_move,
                        color: Color(0xFF1565C0),
                        size: 18),

                    SizedBox(width: 8),

                    Text("Move Categories"),
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
                hintText:
                "Search categories...",

                prefixIcon:
                const Icon(Icons.search),

                filled: true,

                fillColor: Colors.grey[100],

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(10),

                  borderSide: BorderSide.none,
                ),
              ),

              onChanged: (val) {

                setState(() {
                  searchText =
                      val.toLowerCase();
                });
              },
            ),
          ),

          // 📦 CATEGORY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(

              stream:
              ref.orderBy('name').snapshots(),

              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(),
                  );
                }

                final data =
                snapshot.data!.docs.where((doc) {

                  final d =
                  doc.data()
                  as Map<String, dynamic>;

                  final name =
                  (d['name'] ?? '')
                      .toString()
                      .toLowerCase();

                  return name.contains(searchText);

                }).toList();

                if (data.isEmpty) {

                  return const Center(
                    child:
                    Text("No Categories"),
                  );
                }

                return ListView.builder(

                  itemCount: data.length,

                  itemBuilder: (context, index) {

                    final c = data[index];

                    final d =
                    c.data()
                    as Map<String, dynamic>;

                    final isSelected =
                    selectedCategories
                        .contains(c.id);

                    return Card(

                      margin:
                      const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),

                      child: ListTile(

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
                        title: Text(
                          d['name'] ?? 'No Name',
                        ),

                        trailing: selectionMode
                            ? Checkbox(
                          value: isSelected,

                          onChanged: (val) {

                            setState(() {

                              if (val == true) {

                                selectedCategories
                                    .add(c.id);

                              } else {

                                selectedCategories
                                    .remove(c.id);
                              }
                            });
                          },
                        )
                            : const Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                        ),
                        onLongPress: () {

                          setState(() {

                            selectionMode = true;

                            selectedCategories.add(c.id);
                          });
                        },
                        onTap: () {

                          if (selectionMode) {

                            setState(() {

                              if (isSelected) {

                                selectedCategories
                                    .remove(c.id);

                              } else {

                                selectedCategories
                                    .add(c.id);
                              }
                            });

                            return;
                          }

                          Navigator.push(
                            context,

                            MaterialPageRoute(
                              builder: (_) =>
                                  CategoryProductsScreen(

                                    brandId:
                                    widget.brandId,

                                    categoryId:
                                    c.id,

                                    categoryName:
                                    d['name'],
                                    categoryImage: d["image"]?.toString() ?? "",
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

      floatingActionButton:
      FloatingActionButton(

        backgroundColor:
        const Color(0xFF1565C0),

        onPressed: () {
          controller.clear();
          imageFile = null;

          showDialog(
            context: context,
            builder: (_) => StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  title: const Text("Add Category"),

                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [

                        GestureDetector(
                          onTap: () async {
                            final picked = await ImagePicker().pickImage(
                              source: ImageSource.gallery,
                            );

                            if (picked != null) {
                              setDialogState(() {
                                imageFile = File(picked.path);
                              });
                            }
                          },
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: imageFile != null
                                ? FileImage(imageFile!)
                                : null,
                            child: imageFile == null
                                ? const Icon(
                              Icons.add_a_photo,
                              size: 30,
                              color: Colors.grey,
                            )
                                : null,
                          ),
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
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (controller.text.trim().isEmpty) return;

                        String imageUrl = "";

                        if (imageFile != null) {
                          imageUrl = await uploadToCloudinary(imageFile!);
                        }

                        await ref.add({
                          "name": controller.text.trim(),
                          "image": imageUrl,
                          "createdAt": Timestamp.now(),
                        });

                        controller.clear();
                        imageFile = null;

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Category added"),
                            backgroundColor: Color(0xFF1565C0),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Text("Add"),
                    ),
                  ],
                );
              },
            ),
          );
        },

        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}