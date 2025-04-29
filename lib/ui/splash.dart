import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mainPage.dart';
import '../sellerApp/mainPage.dart';
import '/loginPage.dart';
import '/ui/homepage.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}




class _SplashState extends State<Splash> {
  String? is_login = '';
  String? access_token = '';
  String? user_type = '';

  void checkAccess() async {
    SharedPreferences sharedP = await SharedPreferences.getInstance();
    access_token = await sharedP.getString('access_token');
    user_type = await sharedP.getString('user_type');
    log("Access Token" + access_token.toString());
    log(user_type.toString());
    if(access_token.toString().isNotEmpty ){
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
