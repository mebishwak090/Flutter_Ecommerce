import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'checkoutPage.dart';

class CartPage extends StatefulWidget {
  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [];
  double totalPrice = 0.0;

  Map<int, bool> checkedItems = {};

  @override
  void initState() {
    super.initState();
    loadCartItems();
  }

  Future<void> loadCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];

    setState(() {
      cartItems = cart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
      for (int i = 0; i < cartItems.length; i++) {
        checkedItems[i] = checkedItems[i] ?? false;
      }
      calculateTotalPrice();
    });
  }

  Future<void> saveCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = cartItems.map((item) => jsonEncode(item)).toList();
    await prefs.setStringList('cart', cart);
    calculateTotalPrice();
  }

  void calculateTotalPrice() {
    setState(() {
      totalPrice = 0.0;
      for (int i = 0; i < cartItems.length; i++) {
        if (checkedItems[i] == true) {
          var item = cartItems[i];
          double price = double.tryParse(item['price'].toString()) ?? 0.0;
          int qty = item['qty'] ?? 1;
          totalPrice += price * qty;
        }
      }
    });
  }

  Future<void> removeCartItem(int index) async {
    setState(() {
      cartItems.removeAt(index);
      Map<int, bool> newCheckedItems = {};
      for (int i = 0; i < cartItems.length; i++) {
        newCheckedItems[i] = i < index ? checkedItems[i]! : checkedItems[i + 1] ?? false;
      }
      checkedItems = newCheckedItems;
      calculateTotalPrice();
    });
    await saveCartItems();
  }

  Future<void> clearCart() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart');
    setState(() {
      cartItems.clear();
      checkedItems.clear();
      totalPrice = 0.0;
    });
  }

  Future<void> removeCheckedItems() async {
    setState(() {
      List<Map<String, dynamic>> remainingItems = [];
      for (int i = 0; i < cartItems.length; i++) {
        if (checkedItems[i] != true) {
          remainingItems.add(cartItems[i]);
        }
      }
      cartItems = remainingItems;
      checkedItems.clear();
      for (int i = 0; i < cartItems.length; i++) {
        checkedItems[i] = false;
      }
    });
    await saveCartItems();
  }

  void checkout() {
    List<Map<String, dynamic>> selectedItems = [];
    for (int i = 0; i < cartItems.length; i++) {
      if (checkedItems[i] == true) {
        selectedItems.add(cartItems[i]);
      }
    }

    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item for checkout')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Checkout'),
        content: const Text('Proceed to Checkout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CheckoutPage(
                    price: totalPrice,
                    selectedItems: selectedItems,
                    onCheckoutSuccess: removeCheckedItems,
                  ),
                ),
              );
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart Page"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: clearCart,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final item = cartItems[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Checkbox(
                        value: checkedItems[index] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            log(index.toString());

                            checkedItems[index] = value ?? false;
                            calculateTotalPrice();
                          });
                        },
                      ),
                      // Item details
                      Expanded(
                        child: ListTile(
                          leading: Image.network(
                            item['image'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(item['name']),
                          subtitle: Text('Rs.${item['price']} x ${item['qty']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () async {
                                  if (item['qty'] > 1) {
                                    setState(() {
                                      item['qty'] -= 1;
                                    });
                                  } else {
                                    removeCartItem(index);
                                  }
                                  await saveCartItems();
                                },
                              ),
                              Text('${item['qty']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () async {
                                  setState(() {
                                    item['qty'] += 1;
                                  });
                                  await saveCartItems();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (cartItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total: Rs.${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: checkout,
                    // onPressed: (){
                    //   log(checkedItems.toString());
                    // },
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}