import 'dart:convert';
import 'dart:developer';
import '/mainPage.dart';
import '/ui/forgetPassword.dart';
import '/ui/homepage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'integration/googleLogin.dart';
import 'sellerApp/mainPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;
  bool _obsecure = true;
  bool _rememberMe = false;
  int _tabTextIndexSelected = 0;
  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  List<BiometricType> _availableBiometrics = [];

  List<DataTab> get _listTextTabToggle => [
    DataTab(title: "Buyer"),
    DataTab(title: "Seller"),
  ];



  void _login() {

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {

      return;
    }
    setState(() {
      isLoading = true;
    });
    postLogin();

  }
  Future<void> _checkBiometrics() async {
    try {
      _canCheckBiometrics = await auth.canCheckBiometrics;
      _availableBiometrics = await auth.getAvailableBiometrics();
      log("Available Biometrics: $_availableBiometrics");
    } on PlatformException catch (e) {
      debugPrint("Biometric error: $e");
    }
    setState(() {});
  }
  Future postLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final response = await http.post(
        Uri.parse('https://api.sarbamfoods.com/accounts/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email":_emailController.text.toString(),
          "password":_passwordController.text.toString(),
        }));
      if(response.statusCode==200 || response.statusCode == 201){

        prefs.setString('access_token', jsonDecode(response.body)['access_token']);
        prefs.setString('user_type', _tabTextIndexSelected.toString());
      //  prefs.setString('user_data', jsonDecode(response.body));
      setState(() {
        isLoading = false;
      });
      _tabTextIndexSelected==1?  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainPage())):
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Mainpage()));
    }else{

      _passwordController.clear();
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
          msg: "Invalid credentials",
          toastLength: Toast.LENGTH_SHORT,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0
      );
    }
    return response;
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _checkBiometrics();

  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color(0xfff5f5f5),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: isLoading
              ? const Center(child: SpinKitFadingCircle(color: Color(0xffBF1E2E), size: 50))
              : SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome",
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Please sign in to continue",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                // Toggle tab
                FlutterToggleTab(
                  width: 90,
                  borderRadius: 30,
                  height: 50,
                  selectedIndex: _tabTextIndexSelected,
                  selectedBackgroundColors: [const Color(0xffBF1E2E)],
                  selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  unSelectedTextStyle: const TextStyle(color: Colors.black87, fontSize: 14),
                  unSelectedBackgroundColors: [Colors.white],
                  dataTabs: _listTextTabToggle,
                  selectedLabelIndex: (index) => setState(() => _tabTextIndexSelected = index),
                  isScroll: false,
                ),

                const SizedBox(height: 50),

                // Email
                _buildInputField(
                  controller: _emailController,
                  hintText: 'Email',
                  icon: Icons.email,
                  inputType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 20),

                // Password
                _buildInputField(
                  controller: _passwordController,
                  hintText: 'Password',
                  icon: Icons.key,
                  obscureText: _obsecure,
                  suffixIcon: IconButton(
                    icon: Icon(_obsecure ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obsecure = !_obsecure),
                  ),
                ),

                const SizedBox(height: 20),

                // Remember me and forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (value) => setState(() => _rememberMe = value ?? true),
                        ),
                        const Text("Remember Me"),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ForgetPassword())),
                      child: const Text("Forgot Password?", style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Login Button
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 50,
                        width: 180,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                        ),
                      ),
                    ),
                    SizedBox(width: 10,),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 50,
                        // width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _authenticateWithBiometrics,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child:  const Icon(Icons.fingerprint,color: Colors.white,),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("OR"),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade400)),
                  ],
                ),

                const SizedBox(height: 20),


                Center(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });

                      UserCredential? userCredential = await _authService.signInWithGoogle();

                      setState(() {
                        isLoading = false;
                      });

                      if (userCredential != null) {

                        if (_tabTextIndexSelected == 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => Mainpage()),
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => MainPage()),
                          );
                        }
                      } else {
                        Fluttertoast.showToast(
                          msg: "Google Sign-In failed. Please try again.",
                          toastLength: Toast.LENGTH_SHORT,
                          backgroundColor: Colors.red,
                          textColor: Colors.white,
                        );
                      }
                    },

                    icon: Image.asset('assets/google_icon.png', height: 24),
                    label: const Text("Sign in with Google"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
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


  Widget _buildInputField({
  required TextEditingController controller,
  required String hintText,
  required IconData icon,
  bool obscureText = false,
  TextInputType inputType = TextInputType.text,
  Widget? suffixIcon,
}) {
  return TextFormField(
    controller: controller,
    obscureText: obscureText,
    keyboardType: inputType,
    style: const TextStyle(fontFamily: "poppins", color: Colors.black),
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: const BorderSide(color: Color(0xffcbcbcb)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50.0),
        borderSide: const BorderSide(color: Color(0xffBF1E2E)),
      ),
    ),
  );
}
Future<void> _authenticateWithBiometrics() async {
    log("Bio Logged in Tried!");
  try {
    bool didAuthenticate = await auth.authenticate(
      localizedReason: 'Please authenticate to login',
      options: const AuthenticationOptions(
        biometricOnly: false,
        stickyAuth: true,
      ),
    );
    if(didAuthenticate){
      log("logged in");
    }
  } on PlatformException catch (e) {
    if (e.code == 'LockedOut') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Too many failed attempts. Please try again in 30 seconds.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint(e.toString());
    }
    log("Bio Login Exception: " + e.toString());
  }

}}