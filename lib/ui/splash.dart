import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  void checkAccess() async {
    SharedPreferences sharedP = await SharedPreferences.getInstance();
    access_token = await sharedP.getString('access_token');
    if(access_token !='' && false ){
      is_login = access_token;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>HomePage() ));
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
