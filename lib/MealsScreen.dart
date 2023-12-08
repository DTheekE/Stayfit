import 'dart:io' as io;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';


import 'package:http/http.dart' as http;

import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'imgprocess.dart';

class MealsScreen extends StatefulWidget {
  final User user;

  MealsScreen({required this.user});

  @override
  _MealsScreenState createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  DateTime selectedDate = DateTime.now();
  List<List<dynamic>> csvData = [];
  GlobalKey<AutoCompleteTextFieldState<String>> key = GlobalKey();
  TextEditingController amountController = TextEditingController();
  double calories = 0.0;
  String selectedFoodItem = "";
  double amount = 0.0;
  double totcalories = 0.0;
  bool isLoading = false;
  final _controller = WebViewController();

  @override
  @override
  void initState() {
    super.initState();
    loadCSV();
    totcalories = 0.0;
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;


  Future<void> _uploadImage(io.File file) async {
    try {
      String userId =
      (_auth.currentUser != null) ? _auth.currentUser!.uid : "unknown_user";
      String fileName = 'img';
          //'img_' + DateTime.now().millisecondsSinceEpoch.toString() + '_' + userId;

      Reference storageReference =
      FirebaseStorage.instance.ref().child('images/$fileName.jpg');

      // Use SettableMetadata to specify that you want to overwrite existing file
      SettableMetadata metadata = SettableMetadata(contentType: 'image/jpeg');

      UploadTask uploadTask = storageReference.putFile(file, metadata);

      await uploadTask.whenComplete(() {
        print('File uploaded successfully!');
      });
    } catch (e) {
      print('Error: $e');
    }
  }


  Future<void> loadCSV() async {
    final String csvString = await rootBundle.loadString('assets/dataset.csv');
    List<List<dynamic>> csvTable = CsvToListConverter().convert(csvString);

    setState(() {
      csvData = csvTable;
    });
  }

  void calculateCalories(double amountInGrams) {
    final foodRow = csvData.sublist(0).firstWhere((row) {
      return row[0].toString().toLowerCase() == selectedFoodItem.toLowerCase();
    }, orElse: () => []);

    if (foodRow.isNotEmpty && foodRow.length > 1) {
      final double caloriesPer100g =
          double.tryParse(foodRow[1].toString()) ?? 0.0;
      final double calculatedCalories =
          (caloriesPer100g * amountInGrams) / 100.0;
      setState(() {
        calories = calculatedCalories;
      });
    } else {
      setState(() {
        calories = 0.0; // Reset to 0 if the food item is not found
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMMM').format(selectedDate);

    return Scaffold(
      appBar: AppBar(
        /*leading: IconButton(
          icon: Icon(Icons.arrow_back),
          color: Colors.blueAccent,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),*/
        actions: <Widget>[
          Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: getGreetingSymbol(),
              ),
            ],
          ),
        ],
        title: Text(
          'Your Meals',
          style: TextStyle(
            fontSize: 25,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.0,
      ),
      body: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _selectDate(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    selectDate(selectedDate.subtract(Duration(days: 1)));
                  },
                ),
                Text(
                  '$formattedDate',
                  style: TextStyle(
                    fontSize: 25,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    selectDate(selectedDate.add(Duration(days: 1)));
                  },
                ),
              ],
            ),
          ),

          ElevatedButton.icon(
            onPressed: () {
              _showMealEntryDialog(context);
            },
            style: customElevatedButtonStyle(),
            icon: Icon(Icons.add),
            label: Text('Add Meal'),
          ),
          if (!isLoading) Text('\nTotal Calories : ${totcalories.toInt()}'),
          if (isLoading)
            Padding(
              padding: EdgeInsets.all(8.0), // Adjust the padding as needed
              child: SpinKitWave(
                size: 15,
                color: Colors.blueGrey,
                type: SpinKitWaveType.center,
              ),
            ),

          // Display the user's meals using StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('meals')
                  .doc(widget.user.uid)
                  .collection('daily_meals')
                  .where('date',
                      isEqualTo: DateFormat('yyyy-MM-dd').format(selectedDate))
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return SpinKitWave(
                      color: Colors.blueGrey, type: SpinKitWaveType.center);
                }

                final meals = snapshot.data!.docs;
                bool n = (!snapshot.hasData || snapshot.data!.docs.isEmpty);

                return ListView.builder(
                    itemCount: meals.length,
                    itemBuilder: (context, index) {
                      if (n) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "Looks like you haven't added any meals yet.\n"
                              "Start by adding a new meal using the 'Add Meal' button above.",
                              style: TextStyle(
                                fontSize: 16, // Adjust the font size as needed
                                color: Colors
                                    .grey, // Change the color to your preference
                              ),
                              textAlign:
                                  TextAlign.center, // Center align the text
                            ),
                          ),
                        );
                      } else {
                        final meal =
                            meals[index].data() as Map<String, dynamic>;
                        final mealText = meal['meal'] as String;
                        final mealTimestamp = meal['timestamp'] as Timestamp;
                        final mealId = meals[index].id;

                        return Card(
                          margin:
                              EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // Adjust the border radius as needed
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(mealText),
                                subtitle: Text(
                                    'Time : ${DateFormat.Hm().format(mealTimestamp.toDate().toLocal())}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _showEditDialog(mealText, mealId);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete),
                                      onPressed: () {
                                        FirebaseFirestore.instance
                                            .collection('meals')
                                            .doc(widget.user.uid)
                                            .collection('daily_meals')
                                            .doc(mealId)
                                            .delete();
                                      },
                                    ),


                                      // the most important part of this example

                                    IconButton(
                                      icon: Icon(Icons.add_a_photo),
                                      onPressed: () async {
                                        try {
                                          var imagePicker = ImagePicker();

                                          var pickedFile = await imagePicker.pickImage(
                                            source: ImageSource.gallery,
                                          );

                                          if (pickedFile != null) {
                                            var fileToUpload = io.File(pickedFile.path);

                                            // Upload the image (replace this with your upload logic)
                                            await _uploadImage(fileToUpload);


                                            openStreamlitAppSilently();
                                          } else {
                                            print('No image selected.');
                                          }
                                        } catch (e) {
                                          print('Error: $e');
                                        }}

                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        AddFoodItemDialog(mealId);
                                      },
                                      style: customElevatedButtonStyle(),
                                      child: Text('Add Food Item'),
                                    ),
                                  ],
                                ),
                              ),
                              // Food items as subcategories
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('meals')
                                    .doc(widget.user.uid)
                                    .collection('daily_meals')
                                    .doc(mealId)
                                    .collection('food_items')
                                    .orderBy('timestamp', descending: true)
                                    .snapshots(),
                                builder: (context, foodSnapshot) {
                                  if (!foodSnapshot.hasData) {
                                    return CircularProgressIndicator();
                                  }

                                  final foodItems = foodSnapshot.data!.docs;

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: foodItems.length,
                                    itemBuilder: (context, index) {
                                      final foodItem = foodItems[index].data()
                                          as Map<String, dynamic>;
                                      final foodItemText =
                                          foodItem['food_item'] as String;
                                      final foodItemTimestamp =
                                          foodItem['timestamp'] as Timestamp;

                                      final foodItemId = foodItems[index].id;

                                      return ListTile(
                                        title: Text(foodItemText),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                'Amount: ${foodItem['amount']}g | Calories: ${foodItem['calories']}'),
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            /*IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: () {
                                              _showEditFoodItemDialog(
                                                foodItemText,
                                                foodItemId,
                                              );
                                            },
                                          ),*/
                                            IconButton(
                                              icon: Icon(Icons.delete),
                                              onPressed: () {
                                                FirebaseFirestore.instance
                                                    .collection('meals')
                                                    .doc(widget.user.uid)
                                                    .collection('daily_meals')
                                                    .doc(mealId)
                                                    .collection('food_items')
                                                    .doc(foodItemId)
                                                    .delete();
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      }
                    });
              },
            ),
          ),
        ],
      ),
    );
  }

  void AddFoodItemDialog(String mealId) {
    String foodItem = "";
    String amount = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Food Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AutoCompleteTextField(
                key: key,
                controller: TextEditingController(text: ''),
                decoration: InputDecoration(
                  labelText: 'Food Item',
                  hintText: 'Enter Food Item',
                ),
                clearOnSubmit: false,
                suggestions:
                    csvData.sublist(0).map((row) => row[0].toString()).toList(),
                itemFilter: (item, query) {
                  return item.toLowerCase().contains(query.toLowerCase());
                },
                itemSorter: (a, b) {
                  return a.compareTo(b);
                },
                itemSubmitted: (item) {
                  setState(() {
                    selectedFoodItem = item;
                  });
                },
                itemBuilder: (context, item) {
                  return Container(
                    padding: EdgeInsets.all(10.0),
                    child: Text(item),
                  );
                },
              ),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  hintText: 'In grams (g)',
                ),
                onChanged: (text) {
                  // You should update your state here, not just a variable
                  setState(() {
                    amount = text;
                  });
                },
              ),
              SizedBox(height: 20), // Add some spacing
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      final double amountInGrams =
                          double.tryParse(amount) ?? 0.0;
                      calculateCalories(amountInGrams);

                      if (selectedFoodItem.isNotEmpty) {
                        FirebaseFirestore.instance
                            .collection('meals')
                            .doc(widget.user.uid)
                            .collection('daily_meals')
                            .doc(mealId)
                            .collection('food_items')
                            .add({
                          'food_item': selectedFoodItem,
                          'amount': amount,
                          'timestamp': FieldValue.serverTimestamp(),
                          'calories': calories,
                        }).then((_) {
                          // Successfully added, close the dialog
                          Navigator.pop(context);
                        }).catchError((error) {
                          // Handle any errors here, e.g., show an error message
                          print('Error adding food item: $error');
                        });
                      }
                    },
                    child: Text('Add'),
                    style: customElevatedButtonStyle(),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text('Cancel'),
                    style: customElevatedButtonStyle(),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void selectDate(DateTime date) {
    setState(() {
      selectedDate = date;
    });
    calculateTotalCaloriesForSelectedDate(date);
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2025),
    );

    if (picked != null && picked != selectedDate) {
      selectDate(picked); // Call your existing selectDate method
    }
  }

  Future<void> calculateTotalCaloriesForSelectedDate(
      DateTime selectedDate) async {
    setState(() {
      isLoading = true;
    });

    final selectedDateString = DateFormat('yyyy-MM-dd').format(selectedDate);
    double totalCalories = 0.0;

    final mealsQuery = FirebaseFirestore.instance
        .collection('meals')
        .doc(widget.user.uid)
        .collection('daily_meals')
        .where('date', isEqualTo: selectedDateString);

    final mealSnapshots = await mealsQuery.get();
    for (final mealDoc in mealSnapshots.docs) {
      final foodItemsQuery = mealDoc.reference.collection('food_items');
      final foodItemsSnapshots = await foodItemsQuery.get();

      for (final foodItemDoc in foodItemsSnapshots.docs) {
        final foodItemData = foodItemDoc.data() as Map<String, dynamic>;
        final calories = foodItemData['calories'] as double;
        totalCalories += calories;
      }
    }

    setState(() {
      totcalories = totalCalories;
      isLoading = false; // Set loading to false after data is loaded
    });
  }

  void _showMealEntryDialog(BuildContext context) {
    String meal = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter a Meal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (text) {
                  meal = text;
                },
                decoration: InputDecoration(labelText: 'Meal Name'),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                if (meal.isNotEmpty) {
                  final mealDate =
                      DateFormat('yyyy-MM-dd').format(selectedDate);

                  FirebaseFirestore.instance
                      .collection('meals')
                      .doc(widget.user.uid)
                      .collection('daily_meals')
                      .add({
                    'meal': meal,
                    'date': mealDate,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                }
              },
              style: customElevatedButtonStyle(),
              child: Text('Add Meal'),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String currentMeal, String mealId) {
    String updatedMeal = currentMeal;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Meal'),
          content: TextField(
            controller: TextEditingController(text: currentMeal),
            onChanged: (text) {
              updatedMeal = text;
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('meals')
                    .doc(widget.user.uid)
                    .collection('daily_meals')
                    .doc(mealId)
                    .update({'meal': updatedMeal});
                Navigator.pop(context);
              },
              child: Text('Save'),
              style: customElevatedButtonStyle(),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
              style: customElevatedButtonStyle(),
            ),
          ],
        );
      },
    );
  }

  void openStreamlitAppSilently() async {
    const url = 'https://stayfit.streamlit.app';

    try {
      // Make an HTTP request to the URL
      final response = await http.get(Uri.parse(url));

      // Process the response if needed
      print('HTTP Status Code: ${response.statusCode}');
    } catch (e) {
      print('Error: $e');
    }
  }
/*void _showEditFoodItemDialog(
      String currentFoodItem,
      String foodItemId,
      ) {
    String updatedFoodItem = currentFoodItem;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Food Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: currentFoodItem),
                onChanged: (text) {
                  updatedFoodItem = text;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('meals')
                    .doc(widget.user.uid)
                    .collection('daily_meals')
                    .doc(foodItemId) // Update the specific food item document
                    .update({
                  'food_item': updatedFoodItem,
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );}*/
}

ButtonStyle customElevatedButtonStyle({
  Color primaryColor = Colors.white,
  Color textColor = Colors.black87,
  double paddingSize = 10.0,
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

Image getGreetingSymbol() {
  return Image.asset(
      'assets/food.png'); // Replace 'sun.png' with the actual image asset path
}
void openStreamlitApp() async {
  const url = 'https://stayfit.streamlit.app/';

  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}