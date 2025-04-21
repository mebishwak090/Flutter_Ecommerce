import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:khalti_flutter/khalti_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import '../integration/khalti.dart';
import 'homepage.dart';

enum PaymentMethod { esewa, cod, khalti }

class CheckoutPage extends StatefulWidget {
  final double price;
  final List<Map<String, dynamic>> selectedItems;
  final Function onCheckoutSuccess;

  CheckoutPage({
    super.key,
    required this.price,
    required this.selectedItems,
    required this.onCheckoutSuccess,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  String currentAddress = '';
  double latitude = 0.0;
  double longitude = 0.0;
  PaymentMethod? selectedPaymentMethod;
  String orderId = '';

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
    orderId = DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> generateAndDownloadPDF() async {
    final pdf = pw.Document();
    final formatter = DateFormat('dd-MM-yyyy hh:mm a');
    final currentDate = formatter.format(DateTime.now());


    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(height: 20),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Order ID: $orderId'),
                    pw.Text('Date: $currentDate'),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Customer Details:'),
                    pw.Text('Name: ${phoneController.text}'),
                    pw.Text('Email: ${emailController.text}'),
                    pw.Text('Address: ${addressController.text}'),
                    pw.Text('Location: $currentAddress'),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text('Order Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Table.fromTextArray(
              headers: ['Product', 'Quantity', 'Unit Price', 'Total'],
              data: widget.selectedItems.map((item) {
                int qty = item['qty'] ?? 1;
                double price = double.tryParse(item['price'].toString()) ?? 0.0;
                double itemTotal = qty * price;
                return [
                  item['name'],
                  qty.toString(),
                  'Rs.${price.toStringAsFixed(2)}',
                  'Rs.${itemTotal.toStringAsFixed(2)}',
                ];
              }).toList(),
              border: null,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.center,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
              },
            ),
            pw.SizedBox(height: 20),
            pw.Divider(),
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.${widget.price.toStringAsFixed(2)}'),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Shipping:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.50.00'),
              ],
            ),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Tax:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Rs.100.00'),
              ],
            ),
            pw.Divider(),
            pw.SizedBox(height: 5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                pw.Text('Rs.${(widget.price + 150).toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ],
            ),
            pw.SizedBox(height: 30),
            pw.Text('Payment Information', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.Text('Payment Method: ${selectedPaymentMethod?.name.toUpperCase() ?? "N/A"}'),
            pw.Text('Payment Status: Completed'),
            pw.SizedBox(height: 30),
            pw.Center(
              child: pw.Text('Thank you for your purchase!', style: pw.TextStyle(fontSize: 16)),
            ),
            pw.SizedBox(height: 10),
            pw.Center(
              child: pw.Text('For any questions, please contact customer support.'),
            ),
          ];
        },
      ),
    );


    try {
      final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
      final path = '${directory.path}/Invoice_$orderId.pdf';
      final file = File(path);
      await file.writeAsBytes(await pdf.save());


      OpenFile.open(path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invoice saved to $path')),
      );
    } catch (e) {
      print('Error generating PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to generate invoice. Please try again.')),
      );
    }
  }

  Future<void> sendOrderEmail(List<Map<String, dynamic>> selectedItems) async {
    final String serviceId = 'service_al7vazj';
    final String templateId = 'template_flcr12v';
    final String userId = 'oPGEMtN0yn6uz_g1n';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    List<Map<String, dynamic>> formattedCartItems = selectedItems.map((item) {
      return {
        'name': item['name'],
        'image_url': item['image'],
        'units': item['qty'] ?? 1,
        'price': item['price'].toString(),
      };
    }).toList();

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'origin': 'http://localhost'
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'order_id': orderId,
          'customer_name': phoneController.text,
          'email': "anuptwri007@gmail.com",
          'orders': formattedCartItems,
          'cost': {
            'shipping': '50',
            'tax': '100',
            'total': widget.price.toString(),
          }
        },
      }),
    );

    if (response.statusCode == 200) {
      // Call the callback to remove checked items from cart
      await widget.onCheckoutSuccess();
      print('Email sent successfully!');

      // Generate PDF after email is sent
      await generateAndDownloadPDF();
    } else {
      print('Failed to send email: ${response.body}');
    }
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    latitude = position.latitude;
    longitude = position.longitude;

    List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
    Placemark place = placemarks[0];
    setState(() {
      currentAddress = '${place.subLocality}, ${place.locality}, ${place.country}';
    });
  }

  void proceedToPayment() {
    if (phoneController.text.isEmpty || emailController.text.isEmpty || currentAddress.isEmpty || selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select a payment method')),
      );
      return;
    }

    // For COD payment method, skip Khalti and process directly
    if (selectedPaymentMethod == PaymentMethod.cod) {
      sendOrderEmail(widget.selectedItems);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Order Placed'),
            content: const Text('Your order has been placed successfully! You will pay on delivery.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    KhaltiScope.of(context).pay(
      config: PaymentConfig(
          amount: (widget.price * 100).toInt(),
          productIdentity: 'shopping-items',
          productName: 'Shopping Items'
      ),
      preferences: [
        PaymentPreference.khalti,
        PaymentPreference.connectIPS,
        PaymentPreference.eBanking,
        PaymentPreference.mobileBanking,
      ],
      onSuccess: (success) {
        print("Payment Success: $success");
        sendOrderEmail(widget.selectedItems);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Payment Successful'),
              content: const Text('Your order has been placed successfully!'),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage()),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
      onFailure: (failure) {
        print("Payment Failed: $failure");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment failed. Please try again.')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Additional Address',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Current Address:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(currentAddress.isEmpty ? 'Fetching address...' : currentAddress),
                ],
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<PaymentMethod>(
              value: selectedPaymentMethod,
              items: PaymentMethod.values.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (method) {
                log(method.toString());
                setState(() {
                  selectedPaymentMethod = method;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Select Payment Method',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Selected Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Image')),
                  DataColumn(label: Text('Product')),
                  DataColumn(label: Text('Quantity')),
                  DataColumn(label: Text('Price')),
                  DataColumn(label: Text('Total')),
                ],
                rows: widget.selectedItems.map((item) {
                  int qty = item['qty'] ?? 1;
                  double price = double.tryParse(item['price'].toString()) ?? 0.0;
                  double itemTotal = qty * price;

                  return DataRow(cells: [
                    DataCell(Image.network(item['image'], width: 50, height: 50)),
                    DataCell(Text(item['name'])),
                    DataCell(Text('${qty}')),
                    DataCell(Text('Rs.${price.toStringAsFixed(2)}')),
                    DataCell(Text('Rs.${itemTotal.toStringAsFixed(2)}')),
                  ]);
                }).toList(),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Total: ",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "Rs.${widget.price.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: proceedToPayment,
              child: const Text('Proceed to Payment'),
            ),
          ],
        ),
      ),
    );
  }
}