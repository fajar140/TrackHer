import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String userId = '';
  String email = '';

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  Future<void> _getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedEmail = prefs.getString('email');
    print('Stored email: $storedEmail'); // Debug: Check if the email is retrieved correctly from SharedPreferences

    if (storedEmail != null) {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:5000/user?email=$storedEmail'),
      );
      print('Response status: ${response.statusCode}'); // Debug: Check the status code of the response
      print('Response body: ${response.body}'); // Debug: Check the body of the response

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('User ID: ${result['id']}'); // Debug: Check the user ID retrieved from the response
        print('Email: ${result['email']}'); // Debug: Check the email retrieved from the response

        setState(() {
          userId = result['id'].toString();
          email = storedEmail; // Assign storedEmail directly
        });
      } else {
        // Handle the error
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    }
  }

  Future<void> _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('email');
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFeb858d),
        title: const Text(
          'Profile',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false, 
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16.0),
              Text(
                'User ID: $userId',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Email: $email',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32.0),
              ElevatedButton(
                onPressed: _logout,
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFeb858d),
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        selectedItemColor: const Color(0xFFeb858d),
        currentIndex: 1, // Sets the Profile button as selected
        onTap: (int index) {
          if (index == 0) {
            Navigator.of(context).pushReplacementNamed('/home'); // Navigate to the home page
          } else if (index == 1) {
          }
        },
      ),
    );
  }
}
