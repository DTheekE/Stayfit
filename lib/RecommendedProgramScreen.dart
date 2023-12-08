import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:stayfitdemo/HomeScreen.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'BMIScreen.dart';
import 'CustomizedProgramScreen.dart';
import 'home.dart';

class RecommendedProgramScreen extends StatelessWidget {
  final User user;
  final double? bmiValue; // You need to pass the BMI value from BMIScreen
  final double gainLoss;
  final String? gender;
  final int? age;
  final double height;
  final double weight;
  final String selectedActivityLevel;
  double surplus = 700;
  double deficit = (-700);
  bool _isEditing = false;
  TextEditingController _startWeight = TextEditingController();
  TextEditingController _goalWeight = TextEditingController();
  TextEditingController _caloricsState = TextEditingController();
  TextEditingController _durationTaken = TextEditingController();
  TextEditingController _carbIntake = TextEditingController();
  TextEditingController _proteinIntake = TextEditingController();
  TextEditingController _fatIntake = TextEditingController();

  // values to be passed

  RecommendedProgramScreen(
      {required this.bmiValue,
      required this.gainLoss,
      required this.gender,
      required this.age,
      required this.height,
      required this.weight,
      required this.selectedActivityLevel,
      required this.user});

  // Get the carb percentage

  @override
  Widget build(BuildContext context) {
    double bmr = calculateMifflinStJeorBMR(gender!, weight!, height!, age!);
    double bmrWact = calculateBMRWithActivityLevel(bmr, selectedActivityLevel);
    double dailyCalories = CaloriesPerDay(gainLoss, bmrWact);
    double carbAsPer = .4;
    double proteinAsPer = .3;
    double fatAsPer = .3;
    double carb = dailyCalories * carbAsPer;
    double protein = dailyCalories * proteinAsPer;
    double fat = dailyCalories * fatAsPer;

    double surplus = 700;
    double deficit = (-700);
    String calState = gainLoss > 0 ? 'Surplus' : 'Deficit';

    _startWeight.text = (weight).toStringAsFixed(1) + ' Kg';

    _goalWeight.text =
        "${(weight + gainLoss).toStringAsFixed(1)} Kg (${gainLoss.toStringAsFixed(1)} kg)";
    _caloricsState.text = deficit.abs().toStringAsFixed(0) + ' cal';

    _durationTaken.text =
        '${CountDown(gainLoss).abs().toStringAsFixed(0)} days';
    _carbIntake.text = "${carbAsPer * 100} % ";
    _proteinIntake.text = "${proteinAsPer * 100} % ";
    _fatIntake.text = "${fatAsPer * 100} %";

    try {
      final databaseRef = FirebaseDatabase.instance.reference();
      final uid = user.uid;

      final userData = {
        'carb': carb.toInt(),
        'protein': protein
            .toInt(), // I assume this should be 'protein' instead of 'carb'
        'fat': fat.toInt(),
        'age': age,
        'bmract': dailyCalories.toInt(),
        'dietTitle' : 'Recommended Program',

      };

      // Update the user's data in the Realtime Database
      databaseRef.child('users').child(uid).child('userPlan').update(userData);
    } catch (e) {
      // Handle any exceptions that might occur during the database update
      print("Error updating user data: $e");
    } finally {
      // Close any necessary resources or perform cleanup if needed
    }
    TextFormField _buildTextFormField({
      String? label,
      TextEditingController? controller,
      TextInputType? keyboardType,
    }) {
      return TextFormField(
        controller: controller,
        readOnly: true,
        enabled: !_isEditing,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(
                12.0), // Adjust the border radius as needed
          ),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 12.0), // Adjust padding as needed
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('StayFit',
          style: TextStyle(
              fontSize: 40,
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontFamily: 'ProductSans'),),
        centerTitle: true, // Center the title
        leading: IconButton(

          icon: Icon(Icons.arrow_back),
          color: Colors.blueAccent,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) =>
                    BMIScreen(user: user), // Pass the user object
              ),
            );
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[

            SizedBox(height: 25),
            Text(
              'Crafting Your Health and Diet Strategy',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'ProductSans'),
            ),
            SizedBox(height: 16),
            Text(
              "Based on your activity level, your daily calorie requirement is ${bmrWact.toStringAsFixed(0)}.",
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                //fontFamily: 'ProductSans'
              ), // Increase font size
            ),
            SizedBox(height: 20),
            Container(
              width: 100.0,
              height: 100.0,
              child: DoughnutChartWithExplode(
                  carbPercentage: carbAsPer,
                  proteinPercentage: proteinAsPer,
                  fatPercentage:fatAsPer),
            ),
            SizedBox(height: 20),
            _buildTextFormField(
              label: 'Start Weight',
              controller: _startWeight,
              keyboardType: TextInputType.numberWithOptions(),
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              label: 'Goal Weight',
              controller: _goalWeight,
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              label: 'Calorie $calState',
              controller: _caloricsState,
            ),
            SizedBox(height: 16),
            _buildTextFormField(
              label: 'Duration',
              controller: _durationTaken,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextFormField(
                    label: 'Carbohydrates',
                    controller: _carbIntake,
                  ),
                ),
                SizedBox(width: 16), // Add spacing between the input fields
                Expanded(
                  child: _buildTextFormField(
                    label: 'Protein',
                    controller:
                        _proteinIntake, // Replace with your controller for protein input
                  ),
                ),
                SizedBox(width: 16), // Add spacing between the input fields
                Expanded(
                  child: _buildTextFormField(
                    label: 'Fat',
                    controller:
                        _fatIntake, // Replace with your controller for fat input
                  ),
                ),
              ],
            ),

            SizedBox(height: 15),
            Text(
              'You are currently in the ' +
                  _getBMICategory(bmiValue!) +
                  ' category.',
              // You can define this function to get the category
              style: TextStyle(
                fontSize: 20,
                color: Colors.black54,
                //fontFamily: 'ProductSans'
              ),
            ),
            SizedBox(height: 16),
            /*Text(
              'Your BMI is ' + bmiValue!.toStringAsFixed(1) + '.',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),*/
            ElevatedButton(
              style: customElevatedButtonStyle(),
              onPressed: () {
                // Handle the action for continuing with the recommended program
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => HomeScreen2(user: user),
                  ),
                );
              },
              child: Text("Begin Your Journey"),
            ),

            TextButton(
              onPressed: () {
                // Navigate to the Sign-Up page
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>  CustomizedPlanScreen (weight: weight,height: height,user: user, bmrWact: bmrWact, ),
                ));
              },
              child: Text('Start Customized Plan',
                  style: TextStyle(
                    //fontWeight: FontWeight.bold,
                    //fontFamily: 'ProductSans',
                    fontSize: 16,
                  )),
            ),
          ],
        ),
      ),
    );
  }

  String _getBMICategory(double bmi) {
    // Implement the logic to get the BMI category here
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 24.9) {
      return 'Normal Weight';
    } else if (bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }

  String gainORloss(double bmi) {
    if (bmi < 18.5) {
      return 'Gained';
    } else if (bmi < 24.9) {
      return 'Gained';
    } else if (bmi < 24.9) {
      return 'Gained';
    } else if (bmi < 29.9) {
      return 'Lost';
    } else {
      return 'Lost';
    }
  }

  double CaloriesPerDay(double gainLoss, double bmr) {
    if (gainLoss < 0) {
      return bmr - 770.0;
    } else {
      return bmr + 770.0;
    }
  }

  double CountDown(double gainLoss) {
    return gainLoss * 10.0;
  }

  double calculateMifflinStJeorBMR(
      String gender, double weight, double height, int age) {
    if (gender == 'Male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else if (gender == 'Female') {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    } else {
      // Handle the case for other genders or provide a default value
      return 0.0; // Or another appropriate default value
    }
  }

  double calculateBMRWithActivityLevel(
      double bmr, String selectedActivityLevel) {
    switch (selectedActivityLevel) {
      case 'Sedentary':
        return bmr * 1.2;
      case 'Lightly Active':
        return bmr * 1.375;
      case 'Moderately Active':
        return bmr * 1.55;
      case 'Very Active':
        return bmr * 1.725;
      case 'Super Active':
        return bmr * 1.9;
      default:
        return bmr;
    }
  }
}

ButtonStyle customElevatedButtonStyle({
  Color primaryColor = Colors.white,
  Color textColor = Colors.black87,
  double paddingSize = 15.0,
  double borderRadiusSize = 15.0,
}) {
  return ButtonStyle(
    foregroundColor: MaterialStateProperty.all<Color>(textColor),
    backgroundColor: MaterialStateProperty.all<Color>(primaryColor),
    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
      EdgeInsets.all(paddingSize),
    ),
    shape: MaterialStateProperty.all<OutlinedBorder>(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadiusSize),
      ),
    ),
    overlayColor: MaterialStateProperty.all<Color>(textColor),
    side: MaterialStateProperty.all<BorderSide>(
      BorderSide(color: textColor, width: 2.0),
    ),
  );
}

class DoughnutChartWithExplode extends StatelessWidget {
  final double carbPercentage;
  final double proteinPercentage;
  final double fatPercentage;

  DoughnutChartWithExplode({
    required this.carbPercentage,
    required this.proteinPercentage,
    required this.fatPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return SfCircularChart(


      series: <CircularSeries>[
        DoughnutSeries<Data, String>(

          dataSource: <Data>[
            Data(
              'Carbohydrates',
              carbPercentage*100,
            ),
            Data('Protein', proteinPercentage*100),
            Data('Fat', fatPercentage*100),
          ],
          xValueMapper: (Data data, _) => data.segment,
          yValueMapper: (Data data, _) => data.value,
          dataLabelSettings: DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            labelIntersectAction: LabelIntersectAction.none,
            textStyle: TextStyle(fontSize: 10),
          ),
          explode: false,
          pointColorMapper: (Data data, _) {
            if (data.segment == 'Carbohydrates') {
              return const Color(0xFFF597AF);
            } else if (data.segment == 'Protein') {
              return const Color(0xFF66B8E7);
            } else if (data.segment == 'Fat') {
              return const Color(0xFFFFD374);
            }
            return Colors.transparent;
          },
          // This line will explode the segment
        ),
      ],

    );
  }
}