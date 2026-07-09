import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'categories_screen.dart';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
class BrandsListScreen extends StatefulWidget {
  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> {
  final brandsRef =
  FirebaseFirestore.instance.collection('brands');

  final TextEditingController searchController =
  TextEditingController();

  String searchText = '';

  final TextEditingController brandController =
  TextEditingController();

  File? imageFile;
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
  void _addBrand() {
    brandController.clear();
    imageFile = null;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add Brand"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  GestureDetector(
                    onTap: () async {
                      final picked = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);

                      if (picked != null) {
                        setDialogState(() {
                          imageFile = File(picked.path);
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                      imageFile != null ? FileImage(imageFile!) : null,
                      child: imageFile == null
                          ? const Icon(Icons.add_a_photo, size: 30)
                          : null,
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: brandController,
                    decoration: const InputDecoration(
                      hintText: "Enter brand name",
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
                  final name = brandController.text.trim();

                  if (name.isEmpty) return;

                  String imageUrl = "";

                  if (imageFile != null) {
                    imageUrl = await uploadToCloudinary(imageFile!);
                  }

                  await brandsRef.add({
                    "name": name,
                    "image": imageUrl,
                    "createdAt": Timestamp.now(),
                  });

                  brandController.clear();
                  imageFile = null;

                  Navigator.pop(context);

                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(
                      content: Text("Brand created successfully"),
                      backgroundColor: Color(0xFF1565C0),
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
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search brands...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
              onChanged: (val) {
                setState(() => searchText = val.toLowerCase());
              },
            ),
          ),

          // 📋 LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: brandsRef
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final brands = snapshot.data!.docs.where((b) {
                  final name = b['name'].toString().toLowerCase();
                  return name.contains(searchText);
                }).toList();

                if (brands.isEmpty) {
                  return const Center(child: Text("No Brands"));
                }

                return ListView.builder(
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final b = brands[index];
                    final data = b.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: data["image"].toString().isNotEmpty
                            ? Image.network(
                          data["image"].toString(),
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
                          b['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>CategoriesScreen(
                                brandId: b.id,
                                brandName: data['name'],
                                brandImage: data['image'] ?? "",
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

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        onPressed: _addBrand,
        child: const Icon(Icons.add),
      ),
    );
  }
}