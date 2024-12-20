import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PredictPage extends StatefulWidget {
  const PredictPage({super.key});

  @override
  _PredictPageState createState() => _PredictPageState();
}

class _PredictPageState extends State<PredictPage> {
  int reproductiveCategory = 0;
  int group = 0;
  int cycleWithPeakOrNot = 0;
  final TextEditingController lengthOfLutealPhaseController = TextEditingController();
  final TextEditingController lengthOfMensesController = TextEditingController();
  final TextEditingController totalMensesScoreController = TextEditingController();
  final TextEditingController numberOfDaysOfIntercourseController = TextEditingController();
  int intercourseInFertileWindow = 0;
  int unusualBleeding = 0;

  String? predictionResult;
  final _formKey = GlobalKey<FormState>();

  bool _validateInput(String input) {
    if (input.isEmpty || input.length > 2 || int.tryParse(input) == null) {
      return false;
    }
    return true;
  }

  @override
  void initState() {
    super.initState();
  }

  void submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email');

      if (email == null) {
        print('Error: No logged-in email found');
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: No logged-in email found'),
        ));
        return;
      }

      const url = 'http://127.0.0.1:5000/predict';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'ReproductiveCategory': reproductiveCategory,
          'Group': group,
          'CycleWithPeakorNot': cycleWithPeakOrNot,
          'LengthofLutealPhase': int.tryParse(lengthOfLutealPhaseController.text) ?? 0,
          'LengthofMenses': int.tryParse(lengthOfMensesController.text) ?? 0,
          'TotalMensesScore': int.tryParse(totalMensesScoreController.text) ?? 0,
          'NumberofDaysofIntercourse': int.tryParse(numberOfDaysOfIntercourseController.text) ?? 0,
          'IntercourseInFertileWindow': intercourseInFertileWindow,
          'UnusualBleeding': unusualBleeding,
        }),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        setState(() {
          predictionResult = result['prediction'].toString();
        });
        // Show dialog with prediction result
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('Prediction Result'),
            content: Text('Your predicted menstrual cycle length is: $predictionResult'),
            actions: <Widget>[
              TextButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFeb858d)), // Button color
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white, // Text color
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      } else {
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        // Show error message using SnackBar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Error: Failed to fetch prediction. Please try again later.'),
        ));
      }
    } catch (e) {
      print('Error: $e');
      // Show error message using SnackBar
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

void deletePrediction() async {
  // Show confirmation dialog
  showDialog(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Confirmation'),
      content: const Text('Are you sure you want to delete the prediction?'),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close the dialog
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFeb858d)), // Button color
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: Colors.white, // Text color
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            // Proceed with deletion
            deletePredictionConfirmed();
            Navigator.of(context).pop(); // Close the dialog
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all<Color>(const Color(0xFFeb858d)), // Button color
          ),
          child: const Text(
            'Delete',
            style: TextStyle(
              color: Colors.white, // Text color
            ),
          ),
        ),
      ],
    ),
  );
}


void deletePredictionConfirmed() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email');

    if (email == null) {
      print('Error: No logged-in email found');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error: No logged-in email found'),
      ));
      return;
    }

    const url = 'http://127.0.0.1:5000/delete_prediction';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode == 200) {
      setState(() {
        predictionResult = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Prediction deleted successfully.'),
      ));
    } else {
      print('Error: ${response.statusCode}');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error: Failed to delete prediction. Please try again later.'),
      ));
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Error: $e'),
    ));
  }
}


@override
void dispose() {
  // Clear form data when PredictPage is disposed
  clearFormData();
  super.dispose();
}

void clearFormData() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Clear all saved form data
  await prefs.remove('reproductiveCategory');
  await prefs.remove('group');
  await prefs.remove('cycleWithPeakOrNot');
  await prefs.remove('lengthOfLutealPhase');
  await prefs.remove('lengthOfMenses');
  await prefs.remove('totalMensesScore');
  await prefs.remove('numberOfDaysOfIntercourse');
  await prefs.remove('intercourseInFertileWindow');
  await prefs.remove('unusualBleeding');
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Predict your Period', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: const Color(0xFFeb858d),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Please answer this questionnaire to predict your menstrual cycle length:', style: TextStyle(fontFamily: 'Poppins')),
                const SizedBox(height: 16.0),
                const Text('Personal Information', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                const Text('Choose Reproductive Category (How Regular is your cycle):', style: TextStyle(fontFamily: 'Poppins')),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: reproductiveCategory,
                      onChanged: (value) {
                        setState(() {
                          reproductiveCategory = value as int;
                        });
                      },
                    ),
                    const Text('Regular', style: TextStyle(fontFamily: 'Poppins')),
                    Radio(
                      value: 1,
                      groupValue: reproductiveCategory,
                      onChanged: (value) {
                        setState(() {
                          reproductiveCategory = value as int;
                        });
                      },
                    ),
                    const Text('Irregular', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 8.0),
                const Text('Group (Please select):', style: TextStyle(fontFamily: 'Poppins')),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: group,
                      onChanged: (value) {
                        setState(() {
                          group = value as int;
                        });
                      },
                    ),
                    const Text('On Birth Control', style: TextStyle(fontFamily: 'Poppins')),
                    Radio(
                      value: 1,
                      groupValue: group,
                      onChanged: (value) {
                        setState(() {
                          group = value as int;
                        });
                      },
                    ),
                    const Text('Not On Birth Control', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 8.0),
                const Text('Cycle with peak (Did your last cycle has Ovulation peak?):', style: TextStyle(fontFamily: 'Poppins')),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: cycleWithPeakOrNot,
                      onChanged: (value) {
                        setState(() {
                          cycleWithPeakOrNot = value as int;
                        });
                      },
                    ),
                    const Text('Yes', style: TextStyle(fontFamily: 'Poppins')),
                    Radio(
                      value: 1,
                      groupValue: cycleWithPeakOrNot,
                      onChanged: (value) {
                        setState(() {
                          cycleWithPeakOrNot = value as int;
                        });
                      },
                    ),
                    const Text('No', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 8.0),
                const Text('Length of Luteal Phase (Please enter the number of days):', style: TextStyle(fontFamily: 'Poppins')),
                TextFormField(
                  controller: lengthOfLutealPhaseController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_validateInput(value!)) {
                      return 'Please enter a valid number of days (0-99)';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 8.0),
                const Text('Length of Menses (Please enter the number of days):', style: TextStyle(fontFamily: 'Poppins')),
                TextFormField(
                  controller: lengthOfMensesController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_validateInput(value!)) {
                      return 'Please enter a valid number of days (0-99)';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 8.0),
                const Text('Total Menses Score (Please enter the score of your previous cycle based on how many times you changed Pads/Tampons during the cycle):', style: TextStyle(fontFamily: 'Poppins')),
                TextFormField(
                  controller: totalMensesScoreController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (!_validateInput(value!)) {
                      return 'Please enter a valid score (0-99)';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 8.0),
                const Text('Number of Days of Intercourse during the cycle (Please enter the number of days):', style: TextStyle(fontFamily: 'Poppins')),
                TextFormField(
                  controller: numberOfDaysOfIntercourseController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),                  
                    ),
                  validator: (value) {
                    if (!_validateInput(value!)) {
                      return 'Please enter a valid number of days (0-99)';
                    }
                    return null;
                  },
                  style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
                  cursorColor: Colors.black,
                ),
                const SizedBox(height: 8.0),
                const Text('Did you have intercourse during fertile window?', style: TextStyle(fontFamily: 'Poppins')),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: intercourseInFertileWindow,
                      onChanged: (value) {
                        setState(() {
                          intercourseInFertileWindow = value as int;
                        });
                      },
                    ),
                    const Text('No', style: TextStyle(fontFamily: 'Poppins')),
                    Radio(
                      value: 1,
                      groupValue: intercourseInFertileWindow,
                      onChanged: (value) {
                        setState(() {
                          intercourseInFertileWindow = value as int;
                        });
                      },
                    ),
                    const Text('Yes', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
                const Text('Did you experience any unusual bleeding during this cycle?', style: TextStyle(fontFamily: 'Poppins')),
                Row(
                  children: <Widget>[
                    Radio(
                      value: 0,
                      groupValue: unusualBleeding,
                      onChanged: (value) {
                        setState(() {
                          unusualBleeding = value as int;
                        });
                      },
                    ),
                    const Text('No', style: TextStyle(fontFamily: 'Poppins')),
                    Radio(
                      value: 1,
                      groupValue: unusualBleeding,
                      onChanged: (value) {
                        setState(() {
                          unusualBleeding = value as int;
                        });
                      },
                    ),
                    const Text('Yes', style: TextStyle(fontFamily: 'Poppins')),
                  ],
                ),
                const SizedBox(height: 16.0),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: submitData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFeb858d), // Button color
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        ),
                        child: const Text('Predict', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                      ),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: deletePrediction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red, // Button color
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                        ),
                        child: const Text('Delete Prediction', style: TextStyle(fontFamily: 'Poppins', color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                if (predictionResult != null) ...[
                  const SizedBox(height: 24.0),
                  Text(
                    'Your predicted menstrual cycle length is: $predictionResult',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 18.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
