import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'predict.dart';
import 'profile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<DateTime> loggedPeriods = [];
  String predictionLength = '';
  List<DateTime> predictedPeriods = [];
  List<DateTime> predictedOvulationDates = [];
  int lengthOfMenses = 0;
  int roundedLength = 0;
  int predictedOvulation = 0;

  @override
  void initState() {
    super.initState();
    fetchPredictionLength(); // Fetch prediction length on initialization
  }

  Future<void> fetchPredictionLength() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? email = prefs.getString('email');

    if (email != null) {
      try {
        final predictionResponse = await http.get(
          Uri.parse('http://127.0.0.1:5000/get_prediction?email=$email'),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
        );

        if (predictionResponse.statusCode == 200) {
          final predictionResult = json.decode(predictionResponse.body);
          setState(() {
            predictionLength = 'Your Cycle Length Prediction is ${predictionResult['rounded_length']}';
            lengthOfMenses = predictionResult['length_of_menses'];
            roundedLength = predictionResult['rounded_length'];
            predictedOvulation = predictionResult['predicted_ovulation'];
          });
        } else {
          setState(() {
            predictionLength = 'No prediction found';
            loggedPeriods.clear();
            predictedPeriods.clear();
            predictedOvulationDates.clear(); // Clear ovulation dates if no prediction found
          });
        }
      } catch (e) {
        print('Error fetching prediction length: $e');
        setState(() {
          predictionLength = 'Failed to load prediction length';
          loggedPeriods.clear();
          predictedPeriods.clear();
          predictedOvulationDates.clear(); // Clear ovulation dates on error
        });
      }
    }
  }

  void logPeriod() async {
    if (lengthOfMenses == 0 || roundedLength == 0) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Prediction Needed', style: TextStyle(fontFamily: 'Poppins')),
            content: const Text('Please kindly fill in the prediction form first.', style: TextStyle(fontFamily: 'Poppins')),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFeb858d),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    if (_selectedDay != null) {
      setState(() {
        if (loggedPeriods.contains(_selectedDay)) {
          loggedPeriods.remove(_selectedDay);
          predictedPeriods.clear();
          predictedOvulationDates.clear(); // Clear predicted ovulation dates if a period is deleted
          predictionLength = 'No prediction found';
        } else {
          loggedPeriods.add(_selectedDay!);

          // Add red circles for the length of the menses
          for (int i = 0; i < lengthOfMenses; i++) {
            DateTime day = _selectedDay!.add(Duration(days: i));
            if (!loggedPeriods.contains(day)) {
              loggedPeriods.add(day);
            }
          }

          // Add blue circles for the predicted period
          predictedPeriods.clear(); // Clear previous predictions
          DateTime startPrediction = _selectedDay!.add(Duration(days: roundedLength));
          for (int i = 0; i < lengthOfMenses; i++) {
            predictedPeriods.add(startPrediction.add(Duration(days: i)));
          }

          // Calculate and add predicted ovulation dates
          predictedOvulationDates.clear(); // Clear previous ovulation dates
          DateTime ovulationStart = _selectedDay!.add(Duration(days: lengthOfMenses + predictedOvulation)); // Last day of menses
          for (int i = 0; i < lengthOfMenses - 2; i++) {
            predictedOvulationDates.add(ovulationStart.add(Duration(days: i)));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Poppins'),
                      ),
                      Text(
                        DateFormat.yMMMMEEEEd().format(DateTime.now()),
                        style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    color: const Color(0xFFeb858d),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Notifications', style: TextStyle(fontFamily: 'Poppins')),
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                'Upcoming Period: ${predictedPeriods.isNotEmpty ? DateFormat.yMMMMd().format(predictedPeriods.first) : "No predictions yet"}',
                                style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Predicted Ovulation: ${predictedOvulationDates.isNotEmpty ? DateFormat.yMMMMd().format(predictedOvulationDates.first) : "No predictions yet"}',
                              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins'),
                            ),
                          ],
                        ), 
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('OK', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFFeb858d),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  if (isSameDay(day, DateTime.now())) {
                    return Center(
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF77bba2),
                        ),
                        width: 35.0,
                        height: 35.0,
                        child: Center(
                          child: Text(
                            '${day.day}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    );
                  }
                  for (DateTime d in loggedPeriods) {
                    if (isSameDay(day, d)) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                          ),
                          width: 35.0,
                          height: 35.0,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  for (DateTime d in predictedPeriods) {
                    if (isSameDay(day, d)) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          width: 35.0,
                          height: 35.0,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  for (DateTime d in predictedOvulationDates) {
                    if (isSameDay(day, d)) {
                      return Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green, // Color for predicted ovulation
                          ),
                          width: 35.0,
                          height: 35.0,
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: logPeriod,
                    child: const Text('Log Period', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFeb858d),
                      minimumSize: const Size(100, 40),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Ensure user is logged in
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      String? email = prefs.getString('email');
                      if (email != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => PredictPage()),
                        );
                      } else {
                        // Handle case where user is not logged in
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text ('Please log in to access prediction page', style: TextStyle(fontFamily: 'Poppins'))),
                        );
                      }
                    },
                    child: const Text('Predict', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFeb858d),
                      minimumSize: const Size(100, 40),
                    ),
                  ),
                ],
              ),
            ),
                        Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Calendar Color Codes:',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 20,
                        height: 20,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 8),
                      const Text('Logged Periods', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 20,
                        height: 20,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      const Text('Predicted Periods', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 20,
                        height: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      const Text('Predicted Ovulation', style: TextStyle(fontFamily: 'Poppins')),
                    ],
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                predictionLength,
                style: const TextStyle(fontSize: 16, fontFamily: 'Poppins'),
              ),
            ),
          ],
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
        onTap: (int index) {
          if (index == 0) {
          } else if (index == 1) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => ProfilePage()),
            );
          }
        },
        currentIndex: 0, // Sets the Home button as selected
      ),

    );
  }
}