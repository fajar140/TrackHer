import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PasswordResetPage extends StatelessWidget {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();

  String? passwordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[0-9])');
    if (!passwordRegex.hasMatch(value)) {
      return 'Password must contain at least one capital letter and one number';
    }
    return null;
  }

  String? confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != newPasswordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<bool> resetPasswordAPI(String email, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(
            'http://127.0.0.1:5000/change_password'), // Replace with your API endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'email': email,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['message'] == 'Password updated successfully';
      } else {
        print('Failed to reset password: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error resetting password: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/request_password_reset');
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
                'Please enter a new password:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 5),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Enter the email address',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              SizedBox(height: 5),
              SizedBox(height: 30),
              TextField(
                controller: newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Enter your new password',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              TextField(
                controller: confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Re-enter the new password',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final passwordError =
                      passwordValidator(newPasswordController.text);
                  final confirmPasswordError =
                      confirmPasswordValidator(confirmPasswordController.text);

                  if (passwordError == null && confirmPasswordError == null) {
                    final email = emailController.text.trim();
                    final response = await resetPasswordAPI(
                      email,
                      newPasswordController.text.trim(),
                    );

                    if (response) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Password reset successful!'),
                      ));
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Failed to reset password. Try again.'),
                      ));
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(passwordError ?? confirmPasswordError!),
                    ));
                  }
                },
                child: Text(
                  'Confirm',
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
