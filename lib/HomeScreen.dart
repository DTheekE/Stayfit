import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stayfitdemo/NewUser.dart';
import 'package:stayfitdemo/login.dart';
import 'package:stayfitdemo/home.dart';
import 'MealsScreen.dart';
import 'account_settings_screen.dart'; // Import the AccountSettingsScreen class
import 'BMIScreen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'caloriecounter.dart';
import 'datasafety.dart';

class HomeScreen2 extends StatefulWidget {
  final User user;



  HomeScreen2({required this.user});


  @override
  _HomeScreen2State createState() => _HomeScreen2State();
}

class _HomeScreen2State extends State<HomeScreen2> {

  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Define _scaffoldKey here

  late List<Widget> _tabs;

  String username = '';
  String imgurl = '';





  @override
  void initState() {
    super.initState();
    _tabs = [
      NutritionApp(user: widget.user),
      MealsScreen(user: widget.user),
      BMIScreen(user: widget.user),

    ];
    final databaseRef = FirebaseDatabase.instance.reference();
    databaseRef.child('users').child(widget.user.uid).child('username2').onValue.listen((usernameEvent) {
      if (usernameEvent.snapshot.value != null) {
        setState(() {
          username = usernameEvent.snapshot.value.toString();
        });
      }

    });

    databaseRef.child('users').child(widget.user.uid).child('profile_picture').onValue.listen((propicEvent) {
      if (propicEvent.snapshot.value != null) {
        setState(() {
          imgurl = propicEvent.snapshot.value.toString();
        });
      }

    });





  }


  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  Image getGreetingSymbol() {
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return Image.asset('assets/gm.png'); // Replace 'sun.png' with the actual image asset path
    } else if (hour < 17) {
      return Image.asset('assets/ga.png'); // Replace 'cloud.png' with the actual image asset path
    } else {
      return Image.asset('assets/ge.png'); // Replace 'moon.png' with the actual image asset path
    }
  }

  void _openSideMenu(BuildContext context) {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _logout(BuildContext context) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => LoginPage()));
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // Remove the debug banner
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(

          toolbarHeight: 80.0,
          title: Text(
            getGreeting(),
            style: TextStyle(
                fontFamily: 'ProductSans',
              fontSize: 36,
              color: Colors.black, // Set the text color to black
              fontWeight: FontWeight.bold,
              // Make the text bold
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.person,size: 36,),
            color: Colors.black,
            onPressed: () => _openSideMenu(context),
          ),
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
          backgroundColor: Colors.white,
          elevation: 0.0, // Remove the divider
        ),
        drawer: Drawer(

          child: Container(
            color: Colors.white,
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[

                UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    image: DecorationImage(
                      image: AssetImage('assets/back.jpeg'),
                      opacity: .2,
                      fit: BoxFit.cover,
                    ),// Change this color to white
                  ),

                  accountName: Text('@$username'),
                  accountEmail: Text(widget.user.email!),
                  currentAccountPicture: CircleAvatar(
                    backgroundImage: NetworkImage(imgurl),
                    child: imgurl == null || imgurl.isEmpty
                        ? Image.asset('assets/profile_picture.png')
                        : null,
                  )
                ),
                ListTile(
                  leading: Icon(Icons.home),
                  title: Text('Home'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen2(user: widget.user)));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  onTap: () {
                    Navigator.pop(context);

                    Navigator.push(context, MaterialPageRoute(builder: (context) => NewUser1(user: widget.user,)));
                  },
                  title: Text('Plans'),
                  enabled: false,

                ),
                ListTile(
                  leading: Icon(Icons.account_circle),
                  title: Text('Manage Your Account'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => AccountSettingsScreen(user: widget.user)));
                  },
                ),

                ListTile(
                  leading: Icon(Icons.check),
                  title: Text('Progress'),
                  enabled: false,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => BMIScreen(user: widget.user)));
                  },

                ),
                ListTile(
                  leading: Icon(Icons.tips_and_updates),
                  title: Text('Tips and Updates'),
                  enabled: false,

                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip),
                  title: Text('Data Safety'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DataSafetyGuaranteeScreen(user: widget.user,)));
                  },

                ),
                ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  enabled: false,

                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Exit'),
                  onTap: () {
                    exitApp();
                  },
                ),
                ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Logout'),
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          iconSize: 30,
          selectedFontSize: 10,

          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',

            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.food_bank),
              label: 'Diary',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.accessibility_new),
              label: 'BMI',
            ),
          ],
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        ),

        body: _tabs[_currentIndex],




      ),
    );
  }
}

ButtonStyle customElevatedButtonStyle({
  Color primaryColor = Colors.white,
  Color textColor = Colors.black,
  double paddingSize = 25.0,
  double borderRadiusSize = 10.0,
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
    overlayColor: MaterialStateProperty.all<Color>(textColor), // Changes the color of the button when pressed
    side: MaterialStateProperty.all<BorderSide>(
      BorderSide(color: textColor, width: 2.0), // Defines the stroke (border)
    ),
  );
}
void exitApp() {
  SystemNavigator.pop(); // This exits the app
}