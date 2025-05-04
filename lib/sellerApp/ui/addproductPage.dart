import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  File? _imageFile;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await showModalBottomSheet<XFile?>(
      context: context,
      builder: (_) => BottomSheet(
        onClosing: () {},
        builder: (_) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                final photo = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                final gallery = await picker.pickImage(source: ImageSource.gallery);
                Navigator.pop(context, gallery);
              },
            ),
          ],
        ),
      ),
    );

    if (pickedFile != null) {
      final directory = await getApplicationDocumentsDirectory();
      final savedImage = await File(pickedFile.path).copy(
        '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png',
      );

      setState(() {
        _imageFile = savedImage;
      });
    }
  }

  Future<void> saveProduct() async {
    final prefs = await SharedPreferences.getInstance();
    final name = nameController.text.trim();
    final price = double.tryParse(priceController.text) ?? 0.0;
    final description = descriptionController.text.trim();

    if (name.isEmpty || price == 0.0 || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields properly")),
      );
      return;
    }

    Map<String, dynamic> newProduct = {
      "name": name,
      "price": price,
      "description": description,
      "image": _imageFile!.path,
      "isApproved": false,
    };

    List<String> existingProducts = prefs.getStringList("user_products") ?? [];
    existingProducts.add(jsonEncode(newProduct));
    await prefs.setStringList("user_products", existingProducts);


  }

  Future<void> createProduct({
    required String name,
    required String image,
    required String price
}) async{
    try{
        await FirebaseFirestore.instance.collection('products').add({
          'name': name,
          'image': _imageFile!.path,
          'price': price,
          'description': descriptionController.text.trim(),
        });
    }catch(e){
      print("Error: $e");
    }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Product")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(_imageFile!, height: 150, width: double.infinity, fit: BoxFit.cover),
              )
                  : Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text("Tap to select an image"),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => {
                createProduct(name: nameController.text,image: '',price: priceController.text ?? "0.0"),
              },
              child: const Text("Save Product"),
            )
          ],
        ),
      ),
    );
  }
}