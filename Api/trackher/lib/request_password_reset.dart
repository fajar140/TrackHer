import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordResetRequestPage extends StatelessWidget {
  final TextEditingController emailAddressController = TextEditingController();

  Future<void> requestPasswordReset(BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/verify_email'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailAddressController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      if (responseBody['status'] == 'success') {
        Navigator.pushReplacementNamed(context, '/verify_password_reset_code');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(responseBody['message']),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to verify email: ${response.body}'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/login');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Image.asset('assets/logo.png'),
              const Text(
                'Password Reset',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'We\'ll send you instructions in email.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 40),
              TextField(
                controller: emailAddressController,
                decoration: InputDecoration(
                  labelText: 'Input your Email Address',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: Text(
                  'Send',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFeb858d),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(
                      context, '/verify_password_reset_code');
                },
                child: Text(
                  'I already have a reset code',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFeb858d),
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
