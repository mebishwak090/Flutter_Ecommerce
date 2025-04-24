import 'dart:convert';
import 'dart:developer';
import 'mainPage.dart';
import '/ui/forgetPassword.dart';
import '/ui/homepage.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'integration/googleLogin.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  int _tabTextIndexSelected = 0;
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

  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 80),
          child: SingleChildScrollView(
            child: isLoading==true?Center(
              child: SpinKitFadingCircle(
                color: Color(0xffBF1E2E),
                size: 50.0,
              ),
            ):Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Welcome",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                ),
                Text(
                  "To the login screen",
                  style: TextStyle(fontSize: 20, color: Colors.grey.withOpacity(0.8)),
                ),
                const SizedBox(height: 30),
                FlutterToggleTab(
                  width: 90,
                  borderRadius: 30,
                  height: 50,
                  selectedIndex: _tabTextIndexSelected,
                  selectedBackgroundColors: [
                    const Color(0xffBF1E2E),
                    const Color(0xffBF1E2E)
                  ],
                  selectedTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  unSelectedTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  unSelectedBackgroundColors: [
                    Colors.white,
                    Colors.white,
                  ],
                  dataTabs: _listTextTabToggle,
                  selectedLabelIndex: (index) {
                    setState(() {
                      _tabTextIndexSelected = index;
                    });
                  },
                  isScroll: false,
                ),

                const SizedBox(height: 100),

                TextFormField(
                    controller: _emailController,
                    cursorColor: Colors.red,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(
                      fontFamily: "poppins",
                      color: Colors.black,
                    ),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelStyle: TextStyle(fontFamily: "poppins",color: Colors.grey,fontSize: 14),
                      hintStyle: TextStyle(fontFamily: "poppins",color: Colors.grey,fontSize: 14),
                      hintText: 'Email of user',
                      contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Color(0xffcbcbcb), width: 1.0),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color:Color(0xffcbcbcb), width: 1.0),
                        borderRadius: BorderRadius.all(Radius.circular(50.0)),
                      ),
                      prefixIcon: Icon(Icons.email),
                    )
                ),
                const SizedBox(height: 20),
                TextFormField(
                  obscureText: _obsecure,
                  controller: _passwordController,
                  decoration:  InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelStyle: TextStyle(color: Colors.grey,fontSize: 14),
                    hintStyle: TextStyle(color: Colors.grey,fontSize: 14),
                    hintText: 'Password',
                    contentPadding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 18.0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xffcbcbcb), width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color:Color(0xffcbcbcb), width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(50.0)),
                    ),
                    prefixIcon: Icon(Icons.key),
                    suffixIcon: GestureDetector(
                        onTap: (){
                          if(_obsecure==true){
                            setState(() {
                              _obsecure=false;
                            });
                          }else{
                            setState(() {
                              _obsecure=true;
                            });
                          }
                        },
                        child: Icon(_obsecure?Icons.remove_red_eye:Icons.remove_red_eye_outlined)),
                  ),

                ),
                const SizedBox(height: 50),
                Checkbox(value: true, onChanged: (value){

                }),
                const SizedBox(height: 50),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgetPassword()));
                    },
                    child: Text(
                      "Forget Password",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: SizedBox(
                    height: 50,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text("Login", style: TextStyle(fontSize: 18, color: Colors.white)),
                    ),
                  ),
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
}