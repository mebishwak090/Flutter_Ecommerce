import 'dart:convert';
import 'dart:developer';
import 'homepage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

import 'enterOtpPage.dart';

class ForgetPassword extends StatefulWidget {
  const ForgetPassword({super.key});

  @override
  State<ForgetPassword> createState() => _ForgetPasswordState();
}

class _ForgetPasswordState extends State<ForgetPassword> {
  final TextEditingController _emailController = TextEditingController();

  Future sendEmail() async {
    final response = await http.post(
        Uri.parse('https://api.sarbamfoods.com/accounts/forgot_password/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          "email":_emailController.text.toString(),
        }));

    if(response.statusCode==200){
      Navigator.push(context, MaterialPageRoute(builder: (context)=>EnterOtpPage()));
    }else{
      Fluttertoast.showToast(
          msg: "Email doesnot exist",
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
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          leading: GestureDetector(
              onTap:(){
                Navigator.pop(context);
              },
              child: Icon(Icons.arrow_back_rounded)),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 80),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                Center(
                  child: const Text(
                    "Enter Email Address",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
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

                const SizedBox(height: 50),

                Center(
                  child: SizedBox(
                    height: 50,
                    width: 150,
                    child: ElevatedButton(
                      onPressed: sendEmail,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text("Submit", style: TextStyle(fontSize: 18, color: Colors.white)),

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