import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mainPage.dart';
import '../sellerApp/mainPage.dart';
import '/loginPage.dart';
import '/ui/homepage.dart';

class Splash1 extends StatefulWidget {
  const Splash1({super.key});

  @override
  State<Splash1> createState() => _Splash1State();
}




class _Splash1State extends State<Splash1> {
  String? is_login = '';
  String? access_token = '';
  String? user_type = '';

  void checkAccess() async {
    SharedPreferences sharedP = await SharedPreferences.getInstance();
    access_token = await sharedP.getString('access_token');
    user_type = await sharedP.getString('user_type');
    log("Access Token" + access_token.toString());
    log(user_type.toString());
    User? user = FirebaseAuth.instance.currentUser;
    if(access_token.toString().isNotEmpty || user != null || true){
      log("Im in");
      is_login = access_token;
      user_type==1?  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>MainPage())):
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Mainpage()));
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>LoginPage() ));
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), (){
      checkAccess();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment:MainAxisAlignment.center,
        children: [
          Center(
            child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text("Welcome",style: TextStyle(fontSize: 30),)),
          ),
          Center(
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }
}


class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  String token = "";

  void checkAccessToken() async {
    SharedPreferences userPefs = await SharedPreferences.getInstance();
    setState(() {
      token = userPefs.getString("token") ?? "";
    });

    if (token.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        checkAccessToken();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.blue,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
    );
  }
}
