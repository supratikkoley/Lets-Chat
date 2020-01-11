import 'package:flutter/material.dart';
import 'package:skychat/pages/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'pages/homepage.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // FirebaseUser user;
  FirebaseAuth _auth = FirebaseAuth.instance;

  Widget _page;

  _getUser() async {
    // GoogleSignInAccount account =  _googleSignIn.currentUser;

    _auth.currentUser().then((_user) {
      if (_user != null) {
        setState(() {
          _page = MyHomePage(
            user: _user,
          );
        });
      } else {
        setState(() {
          _page = LoginPage();
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _getUser();
  }

  Animation<Color> colors = AlwaysStoppedAnimation(Colors.blue[700]);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Sky Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          accentColor: Colors.blue[800],
          // brightness: Brightness.dark
        ),
        // darkTheme: ThemeData.dark(),
        home: _page == null
            ? Container(
                color: Colors.white,
                child: Center(
                  child: CircularProgressIndicator(
                    // valueColor: colors
                  ),
                ),
              )
            : _page,
        );
  }
}
