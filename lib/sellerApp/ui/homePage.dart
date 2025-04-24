import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'addproductPage.dart';
import 'editProduct.dart';


class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> productStrings = prefs.getStringList("user_products") ?? [];

    setState(() {
      products = productStrings
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList();
    });
  }

  Future<void> approveProduct(int index) async {
    setState(() {
      products[index]['isApproved'] = true;
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      "user_products",
      products.map((e) => jsonEncode(e)).toList(),
    );
  }
  Future<void> cancelApproveProduct(int index) async {
    setState(() {
      products[index]['isApproved'] = false;
    });

    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(
      "user_products",
      products.map((e) => jsonEncode(e)).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // You can filter approved products like this:
    final approvedProducts = products.where((p) => p['isApproved'] == true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Products"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductPage()),
              );
              loadProducts();
            },
          )
        ],
      ),
      body: products.isEmpty
          ? const Center(child: Text("No products added yet."))
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          final isApproved = product['isApproved'] == true;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            color: isApproved ? Colors.white : Colors.yellow[100],
            child: ListTile(
              leading: product['image'] != null
                  ? Image.file(
                File(product['image']),
                width: 50,
                height: 50,
                fit: BoxFit.cover,
              )
                  : const Icon(Icons.image),
              title: Text(product['name']),
              subtitle: Text("Rs. ${product['price']}"),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isApproved)
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      tooltip: "Approve",
                      onPressed: () => approveProduct(index),
                    ),
                  if(isApproved)
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.green),
                      tooltip: "Approve",
                      onPressed: () => cancelApproveProduct(index),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      products.removeAt(index);
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setStringList(
                        "user_products",
                        products.map((e) => jsonEncode(e)).toList(),
                      );
                      loadProducts();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      products.removeAt(index);
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setStringList(
                        "user_products",
                        products.map((e) => jsonEncode(e)).toList(),

                      );

                    //  Navigator.push(
                   //     context,
                       // MaterialPageRoute(
                         // builder: (context) => EditProductPage(product: index),
                       // ),
                   //   );
                      loadProducts();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
