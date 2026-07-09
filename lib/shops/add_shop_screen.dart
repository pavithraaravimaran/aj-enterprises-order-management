import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddShopScreen extends StatefulWidget {
  const AddShopScreen({super.key});

  @override
  State<AddShopScreen> createState() =>
      _AddShopScreenState();
}

class _AddShopScreenState extends State<AddShopScreen> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String address = '';
  String phone = '';
  String note = '';

  bool isLoading = false;

  final shopsRef =
  FirebaseFirestore.instance.collection('shops');

  // 💾 SAVE SHOP
  Future<void> addShop() async {
    setState(() => isLoading = true);

    try {
      await shopsRef.add({
        'name': name,
        'address': address,
        'phone': phone,
        'note': note,
        'createdAt': Timestamp.now(),
      });

      setState(() => isLoading = false);

      // 🔵 FLOATING SUCCESS SNACKBAR
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Shop added successfully"),
          backgroundColor: const Color(0xFF1565C0),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      // 🔴 ERROR SNACKBAR (ALSO FLOATING)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add shop: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Shop")),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // 🏪 NAME
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Shop Name",
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty
                      ? "Enter name"
                      : null,
                  onSaved: (v) => name = v!,
                ),

                const SizedBox(height: 10),

                // 📍 ADDRESS
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Address",
                  ),
                  validator: (v) =>
                  v == null || v.isEmpty
                      ? "Enter address"
                      : null,
                  onSaved: (v) => address = v!,
                ),

                const SizedBox(height: 10),

                // 📞 PHONE (10 digit validation)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Phone",
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Enter phone number";
                    }
                    if (v.length != 10) {
                      return "Phone must be 10 digits";
                    }
                    return null;
                  },
                  onSaved: (v) => phone = v ?? '',
                ),

                const SizedBox(height: 10),

                // 📝 NOTE (OPTIONAL)
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Note (optional)",
                  ),
                  maxLines: 3,
                  onSaved: (v) => note = v ?? '',
                ),

                const SizedBox(height: 20),

                // 💾 SAVE BUTTON
                isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (_formKey.currentState!
                          .validate()) {
                        _formKey.currentState!.save();
                        addShop();
                      }
                    },
                    child: const Text("Save Shop"),
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