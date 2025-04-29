import 'dart:convert';
import 'dart:developer';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ecommerce/ui/splash.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'productDetailPage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../integration/googleLogin.dart';
import 'cartPage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  TextEditingController searchController = TextEditingController();

  final List<String> images = [
    'https://www.w3schools.com/w3images/lights.jpg',
    'https://www.w3schools.com/w3images/mountains.jpg',
    'https://www.w3schools.com/w3images/forest.jpg',
  ];

  final List<Map<String, dynamic>> products = [

  ];

  final _controller = YoutubePlayerController.fromVideoId(
    videoId: 'jqxz7QvdWk8',
    autoPlay: false,
    params: const YoutubePlayerParams(showFullscreenButton: true),
  );

  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> filteredProducts = [];
  List<String> videoIds = [];
  String selectedVideoId = '';

  @override
  void initState() {
    super.initState();
    loadCartItems();
    loadProfileImage();
    loadUserProducts();
    fetchVideos();
    filteredProducts = products;
  }

  Future<void> fetchVideos() async {
    final snapshot = await FirebaseFirestore.instance.collection('videos').get();
    List<String> ids = [];
    for (var doc in snapshot.docs){
      final List<dynamic> videoList = doc['videoid'];
      ids.addAll(videoList.map((e) => e.toString()));
      log(videoList.toString());
    }

    setState(() {
      videoIds = ids;
      if(videoIds.isNotEmpty){
        selectedVideoId = videoIds.first;
        _controller.loadVideoById(videoId: selectedVideoId);
      }
    });
  }


  Future<void> _startScanning() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          child: ScannerView(
            onBarcodeDetected: (String barcode) async {
              log(barcode);
              setState(() {
                searchController = TextEditingController(text: barcode);
                filteredProducts = products.where((product) {
                  final nameMatch = product['name']
                      .toLowerCase()
                      .contains(barcode.toLowerCase());
                  final priceMatch = double.tryParse(barcode) != null &&
                      product['price'].toString().contains(barcode);
                  return nameMatch || priceMatch;
                }).toList();

              });
              if(filteredProducts.isEmpty){
                Fluttertoast.showToast(msg: "No Product Found with this name");
              }
              Navigator.pop(context);

            },
          ),
        ),
      ),
    );
  }
  Future<void> loadUserProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final userProductStrings = prefs.getStringList("user_products") ?? [];

    final userProductMaps = userProductStrings
        .map((json) => jsonDecode(json) as Map<String, dynamic>)
        .toList();

    setState(() {
      products.addAll(userProductMaps);
      filteredProducts = products;
    });
  }
  String? _imagePath;
  Future<void> loadProfileImage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _imagePath = prefs.getString('profile_image');
    });
  }

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
              leading: const Icon(Icons.camera),
              title: const Text("Take Photo"),
              onTap: () async {
                final photo = await picker.pickImage(source: ImageSource.camera);
                Navigator.pop(context, photo);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Choose from Gallery"),
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
      final savedImage = await File(pickedFile.path).copy('${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', savedImage.path);

      setState(() {
        _imagePath = savedImage.path;
      });
    }
  }

  Future<void> loadCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];

    setState(() {
      cartItems = cart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();
    });
  }
  Future<void> logMeOut () async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    log("im inside logout");
    prefs.remove('access_token');
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Splash()));
  }

  Future<void> addToCart(Map<String, dynamic> product) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> cart = prefs.getStringList('cart') ?? [];

    List<Map<String, dynamic>> cartList =
    cart.map((item) => jsonDecode(item) as Map<String, dynamic>).toList();

    int index = cartList.indexWhere((item) => item['name'] == product['name']);
    log("got index:"+index.toString());
    if (index != -1) {
      cartList[index]['qty'] = (cartList[index]['qty']??1) + 1;
    } else {
      product['qty'] = 1;
      cartList.add(product);
      cartList.add(product);
    }
    await prefs.setStringList(
      'cart',
      cartList.map((item) => jsonEncode(item)).toList(),
    );

    loadCartItems();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to cart!')),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        automaticallyImplyLeading: true,
        backgroundColor: Colors.teal,
        title: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              filteredProducts = products.where((product) {
                final nameMatch = product['name']
                    .toLowerCase()
                    .contains(value.toLowerCase());

                final priceMatch = double.tryParse(value) != null &&
                    product['price'].toString().contains(value);

                return nameMatch || priceMatch;
              }).toList();

            });
          },
        ),
        actions: [
          ElevatedButton(onPressed: (){
            _startScanning();
          }, child: Text("Scan")),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CartPage()),
                    ).then((_) => loadCartItems());
                  },
                ),
                if (cartItems.isNotEmpty)
                  Positioned(
                    right: 4,
                    top: 1,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        cartItems.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.teal),
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _imagePath != null
                          ? FileImage(File(_imagePath!))
                          : const AssetImage('assets/icon.jpg') ,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(Icons.camera_alt, size: 20),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text("Home"),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Cart"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CartPage()),
                ).then((_) => loadCartItems());
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text("Log Out"),
              onTap:  logMeOut,
            ),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarouselSlider(
                options: CarouselOptions(
                  height: 200,
                  enlargeCenterPage: true,
                  autoPlay: true,
                  aspectRatio: 16 / 9,
                  viewportFraction: 0.8,
                ),
                items: images.map((imageUrl) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductDetailPage(product: product),
                          ),
                        );
                      },
                      child: ProductCard(
                        image: product['image'],
                        name: product['name'],
                        price: product['price'],
                        onAddToCart: () => addToCart(product),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 50,),
              Container(
                child: YoutubePlayer(
                  controller: _controller,
                  aspectRatio: 16 / 9,
                ),
              ),
              SizedBox(
                height: 830,
                width: MediaQuery.of(context).size.width,
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                  ),
                  itemCount: videoIds.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GestureDetector(
                        onTap: (){
                          _controller.loadVideoById(videoId: videoIds[index]);
                        },
                        child: Column(
                          children: [
                            Expanded(
                                child: Image.network(
                                  "https://img.youtube.com/vi/${videoIds[index]}/hqdefault.jpg",
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  ),
                          ),
                          ]
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 50,),
              Row(
                children: [
                  Container(
                    height:  MediaQuery.of(context).size.height/4,
                    width: MediaQuery.of(context).size.width/2.1,
                    color: Colors.red,
                  ),
                  SizedBox(width: 10,),
                  Container(
                    height:  MediaQuery.of(context).size.height/4,
                    width: MediaQuery.of(context).size.width/2.2,
                    color: Colors.red,
                  ),
                  // SizedBox(width: 10,),
                  // Container(
                  //   height:  MediaQuery.of(context).size.height/7,
                  //   width: MediaQuery.of(context).size.width/5,
                  //   color: Colors.red,
                  // ),
                ],
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final String image;
  final String name;
  final double price;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.image,
    required this.name,
    required this.price,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width/3,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.file( File(image!), height: 80, width: 80, fit: BoxFit.cover),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Rs.${price.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.green)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: onAddToCart,
            child: const Text('Add to Cart'),
          ),
        ],
      ),
    );
  }
}


class ScannerView extends StatefulWidget {
  final Function(String) onBarcodeDetected;

  const ScannerView({
    Key? key,
    required this.onBarcodeDetected,
  }) : super(key: key);

  @override
  State<ScannerView> createState() => _ScannerViewState();
}
class _ScannerViewState extends State<ScannerView> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Scanner
            MobileScanner(
              controller: controller,
              onDetect: (capture) {
                if (_isProcessing) return;
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                  setState(() => _isProcessing = true);
                  widget.onBarcodeDetected(barcodes.first.rawValue!);
                }
              },
            ),

            // Overlay
            Container(
              decoration: ShapeDecoration(
                shape: ScannerOverlayShape(
                  borderColor: Colors.white,
                  borderRadius: 12,
                  borderLength: 32,
                  borderWidth: 3,
                  cutOutSize: 250,
                ),
              ),
            ),

            // Animated Scanner Line
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: ScannerLinePainter(
                      progress: _animation.value,
                      color: Theme.of(context).primaryColor.withOpacity(0.5),
                    ),
                  );
                },
              ),
            ),

            // Top Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    // ValueListenableBuilder(
                    //   valueListenable: controller.torchState,
                    //   builder: (context, state, child) {
                    //     return IconButton(
                    //       icon: Icon(
                    //         state == TorchState.off ? Icons.flash_off : Icons.flash_on,
                    //         color: Colors.white,
                    //       ),
                    //       onPressed: () => controller.toggleTorch(),
                    //     );
                    //   },
                    // ),
                  ],
                ),
              ),
            ),

            // Bottom Instructions
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Align barcode within frame',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scanner will detect automatically',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    controller.dispose();
    super.dispose();
  }
}
class ScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final Color overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const ScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 3.0,
    this.overlayColor = const Color(0x80000000),
    this.borderRadius = 12.0,
    this.borderLength = 32.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path _getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }

    return _getLeftTopPath(rect);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final height = rect.height;
    final cutOutWidth = cutOutSize;
    final cutOutHeight = cutOutSize;
    final left = rect.left + (width - cutOutWidth) / 2;
    final top = rect.top + (height - cutOutHeight) / 3;
    final right = left + cutOutWidth;
    final bottom = top + cutOutHeight;

    final cutOutRect = Rect.fromLTRB(left, top, right, bottom);
    final backgroundPaint = Paint()..color = overlayColor;
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect)
      ..addRRect(RRect.fromRectAndRadius(
        cutOutRect,
        Radius.circular(borderRadius),
      ));

    canvas.drawPath(path, backgroundPaint);

    // Draw corners
    final borderOffset = borderWidth / 2;
    final cornerStart = borderLength;

    // Top left corner
    canvas.drawLine(
      Offset(left - borderOffset, top + cornerStart),
      Offset(left - borderOffset, top - borderOffset),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left - borderOffset, top - borderOffset),
      Offset(left + cornerStart, top - borderOffset),
      borderPaint,
    );

    // Top right corner
    canvas.drawLine(
      Offset(right - cornerStart, top - borderOffset),
      Offset(right + borderOffset, top - borderOffset),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right + borderOffset, top - borderOffset),
      Offset(right + borderOffset, top + cornerStart),
      borderPaint,
    );

    // Bottom right corner
    canvas.drawLine(
      Offset(right + borderOffset, bottom - cornerStart),
      Offset(right + borderOffset, bottom + borderOffset),
      borderPaint,
    );
    canvas.drawLine(
      Offset(right + borderOffset, bottom + borderOffset),
      Offset(right - cornerStart, bottom + borderOffset),
      borderPaint,
    );

    // Bottom left corner
    canvas.drawLine(
      Offset(left + cornerStart, bottom + borderOffset),
      Offset(left - borderOffset, bottom + borderOffset),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left - borderOffset, bottom + borderOffset),
      Offset(left - borderOffset, bottom - cornerStart),
      borderPaint,
    );
  }

  @override
  ShapeBorder scale(double t) {
    return ScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
    );
  }
}
class ScannerLinePainter extends CustomPainter {
  final double progress;
  final Color color;

  ScannerLinePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0;

    final scanLineY = size.height * 0.3 + (size.height * 0.4 * progress);
    canvas.drawLine(
      Offset(size.width * 0.2, scanLineY),
      Offset(size.width * 0.8, scanLineY),
      paint,
    );
  }

  @override
  bool shouldRepaint(ScannerLinePainter oldDelegate) => true;
}