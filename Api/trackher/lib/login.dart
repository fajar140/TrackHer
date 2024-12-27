import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController forgotPasswordController =
      TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> login(BuildContext context) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/login'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': emailController.text,
        'password': passwordController.text,
      }),
    );

    if (response.statusCode == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', emailController.text);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Login successful!'),
      ));
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to login: ${response.body}'),
      ));
    }
  }

  Future<void> showForgotPasswordPopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Forgot Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter your email to reset your password'),
              SizedBox(height: 10),
              TextField(
                controller: forgotPasswordController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = forgotPasswordController.text.trim();

                if (email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Email cannot be empty'),
                  ));
                  return;
                }

                final response = await http.post(
                  Uri.parse(
                      'http://127.0.0.1:5000/verify_email'), // Replace with your API endpoint
                  headers: <String, String>{
                    'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(<String, String>{
                    'email': email,
                  }),
                );

                if (response.statusCode == 200) {
                  final responseBody = jsonDecode(response.body);
                  if (responseBody['status'] == 'success') {
                    Navigator.of(context).pop();
                    verifyCodePopup(context);
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
              },
              child: Text('Next'),
            ),
          ],
        );
      },
    );
  }

  Future<void> verifyCodePopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter the code sent to your email'),
              SizedBox(height: 10),
              TextField(
                controller: codeController,
                decoration: InputDecoration(
                  labelText: 'Code',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (codeController.text == 'ABC123') {
                  Navigator.of(context).pop();
                  resetPasswordPopup(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Invalid code!'),
                  ));
                }
              },
              child: Text('Verify'),
            ),
          ],
        );
      },
    );
  }

  Future<void> resetPasswordPopup(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 10),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final passwordError =
                    passwordValidator(newPasswordController.text);
                final confirmPasswordError =
                    confirmPasswordValidator(confirmPasswordController.text);

                if (passwordError == null && confirmPasswordError == null) {
                  final email = forgotPasswordController.text.trim();
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
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        /*title: Text(
          'Login',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),*/
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/');
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Spacer(flex: 1),
              Image.asset('assets/logo.png'),
              const Text(
                'Log In',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Please log in to continue using this app.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(fontFamily: 'Poppins'),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                style: TextStyle(fontFamily: 'Poppins'),
              ),
              //SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, '/request_password_reset');
                    },
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: Color(0xFFeb858d),
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFFeb858d),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => login(context),
                child: Text(
                  'Login',
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
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                child: RichText(
                  text: TextSpan(
                    text: 'Don\'t have an account? ',
                    style: TextStyle(
                      color: Color(0xFFeb858d),
                      fontFamily: 'Poppins',
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
