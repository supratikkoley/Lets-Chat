import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skychat/pages/homepage.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final databaseRef = Firestore.instance;

  FirebaseUser user;

  bool _isNewUser = true;

  Future<FirebaseUser> signInWithGoogle() async {
    final GoogleSignInAccount googleSignInAccount = await googleSignIn.signIn();
    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleSignInAuthentication.accessToken,
      idToken: googleSignInAuthentication.idToken,
    );

    final AuthResult _authResult = await _auth.signInWithCredential(credential);

    user = _authResult.user;

    _isNewUser = _authResult.additionalUserInfo.isNewUser;

    assert(!user.isAnonymous);
    assert(await user.getIdToken() != null);

    final FirebaseUser currentUser = await _auth.currentUser();
    assert(user.uid == currentUser.uid);
    print(user?.displayName);
    return user;
  }

  _createUser(FirebaseUser user) async {
    await databaseRef.collection('users').document(user.email).setData({
      'username': user.displayName,
      'email': user.email,
      'photo': user.photoUrl,
      'friends': [],
    }).whenComplete(() {
      print("User created");
    });
  }

  void _onLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          content: Container(
            // height: 40.0,
            // margin: EdgeInsets.all(8.0),
            child: new Row(
              // mainAxisSize: MainAxisSize.min,
              children: [
                new CircularProgressIndicator(),
                SizedBox(
                  width: 35.0,
                ),
                new Text("Loading...", style: TextStyle(fontSize: 20.0)),
              ],
            ),
          ),
        );
      },
    );
    new Future.delayed(new Duration(microseconds: 0), () {
      //pop dialog
      signInWithGoogle().then((user) {
        if (user != null) {
          if (_isNewUser) {
            _createUser(user);
          }
          Navigator.pop(context);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MyHomePage(
                user: user,
              ),
            ),
          );
          // _isNewUser
          //     ? Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //             builder: (context) => ProfileFormPage(
          //                   user: user,
          //                 ) //MainPage(selIndex: 0, user: user),
          //             ),
          //       )
          //     : Navigator.pushReplacement(
          //         context,
          //         MaterialPageRoute(
          //           builder: (context) => MainPage(
          //             selIndex: 0,
          //             user: user,
          //           ),
          //         ),
          // );
        } else {
          Navigator.pop(context);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Container(
            color: Colors.white,
            // child: Image.asset(
            //   "assets/images/splash.png",
            //   fit: BoxFit.fill,
            // ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.8,
            child: InkWell(
              onTap: _onLoading,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: 50.0,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(360.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      // Container(
                      //   height: 40.0,
                      //   width: 80.0,
                      Image.asset(
                        "assets/google_sign_in_logo.png",
                        height: 40.0,
                        // ),
                      ),
                      SizedBox(
                        width: 24.0,
                      ),
                      Text(
                        "Sign In with Google",
                        style: TextStyle(
                          fontSize: 22.0,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
