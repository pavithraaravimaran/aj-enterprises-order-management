import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  final String brandId;
  final String categoryId;
  final String? productId;
  final Map<String, dynamic>? existingData;

  const AddProductScreen({
    required this.brandId,
    required this.categoryId,
    this.productId,
    this.existingData,
  });

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController nameController;
  late TextEditingController mrpController;
  late TextEditingController retailController;
  late TextEditingController gstController; // ✅ NEW

  File? imageFile;
  String existingImage = "";

  bool isLoading = false;

  CollectionReference get productsRef => FirebaseFirestore.instance
      .collection('brands')
      .doc(widget.brandId)
      .collection('categories')
      .doc(widget.categoryId)
      .collection('products');

  @override
  void initState() {
    super.initState();

    nameController =
        TextEditingController(text: widget.existingData?['name'] ?? '');
    mrpController =
        TextEditingController(text: widget.existingData?['mrp']?.toString() ?? '');
    retailController =
        TextEditingController(text: widget.existingData?['retail']?.toString() ?? '');
    gstController =
        TextEditingController(text: widget.existingData?['gst']?.toString() ?? '');

    existingImage = widget.existingData?['image'] ?? '';
  }

  Future<void> pickImage() async {
    final picked =
    await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        imageFile = File(picked.path);
      });
    }
  }

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

  // ✅ CLEAN SNACKBAR
  void showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
        isError ? Colors.red : const Color(0xFF1565C0),
      ),
    );
  }

  Future<void> saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      String imageUrl = existingImage;

      if (imageFile != null) {
        imageUrl = await uploadToCloudinary(imageFile!);
      }

      final data = {
        'name': nameController.text.trim(),
        'mrp': double.tryParse(mrpController.text) ?? 0,
        'retail': double.tryParse(retailController.text) ?? 0,
        'gst': double.tryParse(gstController.text) ?? 0, // ✅ NEW
        'image': imageUrl,
      };

      if (widget.productId == null) {
        await productsRef.add({
          ...data,
          'createdAt': Timestamp.now(),
        });

        showMsg("Product Added Successfully");
      } else {
        await productsRef.doc(widget.productId).update(data);

        showMsg("Product Updated Successfully");
      }

      Navigator.pop(context);
    } catch (e) {
      showMsg("Error occurred", isError: true);
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.productId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? "Edit Product" : "Add Product"),
        backgroundColor: const Color(0xFF1565C0),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [

                Stack(
                  children: [
                    GestureDetector(
                      onTap: pickImage,
                      child: Container(
                        height: 170,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: imageFile != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            imageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : existingImage.isNotEmpty
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            existingImage,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 8),
                              Text("Tap to add image"),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // DELETE IMAGE BUTTON
                    if (imageFile != null || existingImage.isNotEmpty)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Material(
                          elevation: 4,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: InkWell(
                            customBorder: const CircleBorder(),
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
                                      onPressed: () =>
                                          Navigator.pop(context, false),
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
                                setState(() {
                                  imageFile = null;
                                  existingImage = '';
                                });

                                showMsg("Image removed");
                              }
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(
                                Icons.delete,
                                color: Colors.red,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                TextFormField(
                  controller: nameController,
                  decoration:
                  const InputDecoration(labelText: "Product Name"),
                  validator: (v) =>
                  v == null || v.isEmpty ? "Enter name" : null,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: mrpController,
                  decoration: const InputDecoration(labelText: "MRP"),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: retailController,
                  decoration:
                  const InputDecoration(labelText: "Retail"),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // ✅ GST FIELD
                TextFormField(
                  controller: gstController,
                  decoration: const InputDecoration(labelText: "GST (%)"),
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 24),

                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: saveProduct,
                    icon: Icon(isEdit ? Icons.update : Icons.add),
                    label: Text(
                      isEdit ? "Update Product" : "Save Product",
                      style: const TextStyle(color: Colors.white), // ✅ WHITE TEXT
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}