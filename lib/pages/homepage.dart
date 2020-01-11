import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:skychat/pages/chatscreen.dart';
import 'package:skychat/pages/login_page.dart';

class MyHomePage extends StatefulWidget {
  final FirebaseUser user;

  MyHomePage({Key key, @required this.user}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final databaseRef = Firestore.instance;

  TextEditingController _newfriendController = TextEditingController();

  _logout() async {
    await googleSignIn.signOut().whenComplete(() {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginPage(),
          ));
    });
  }

  @override
  void dispose() {
    _newfriendController.dispose();
    super.dispose();
  }

  Future<void> _addFriend(String friendsEmail) async {
    DocumentReference newfriend = Firestore.instance
        .collection('users')
        .document(friendsEmail.toLowerCase());

    if (friendsEmail == widget.user.email) {
      print("You can't add yourself !!!"); //todo
      Fluttertoast.showToast(
          msg: "You can't add yourself !!!", gravity: ToastGravity.CENTER);
      return;
    }
    await newfriend.get().then((friend) {
      if (friend.data != null) {
        databaseRef
            .collection('users')
            .document(widget.user.email)
            .get()
            .then((doc) {
          if (doc != null) {
            if (doc.data.isNotEmpty) {
              List friendsList = doc.data['friends'].toList();
              print(friendsList);
              if (!friendsList.contains(newfriend)) {
                friendsList.add(newfriend);
                databaseRef
                    .collection('users')
                    .document(widget.user.email)
                    .updateData({
                  'friends': friendsList,
                });
              } else {
                print(
                    "This friend is already added to your friend list."); //todo
                Fluttertoast.showToast(
                  msg: "This friend is already added to your friend list",
                  gravity: ToastGravity.CENTER,
                );
              }
            }
          }
        });
      } else {
        print("Wrong email or email does not exist in our app"); //todo
        Fluttertoast.showToast(
                  msg: "Wrong email or email does not exist in our app",
                  gravity: ToastGravity.CENTER,

                );
      }
    });
  }

  showEmailInputBox() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
        ),
        builder: (context) {
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(9.0),
                  child: Text("Add your friend",style: TextStyle(fontSize: 20.0,fontWeight: FontWeight.w500)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: TextField(
                    autofocus: true,
                    controller: _newfriendController,
                    style: TextStyle(fontSize: 18.0),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      // border: InputBorder.none,
                      hintText: "Type your friend's email",
                    ),
                  ),
                ),
                SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        FlatButton(
                          splashColor: Colors.blue,
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 16.0,
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        // SizedBox(width: 5.0),
                        FlatButton(
                          splashColor: Colors.blue,
                          child: Text(
                            "Add",
                            style:
                                TextStyle(color: Colors.blue, fontSize: 16.0),
                          ),
                          onPressed: () {
                            if (_newfriendController.text != null &&
                                _newfriendController.text != '') {
                              _addFriend(_newfriendController.text)
                                  .whenComplete(() {
                                _newfriendController.clear();
                              });
                              Navigator.pop(context);
                            }
                          },
                        )
                      ],
                    )
                  ],
                )
              ],
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // centerTitle: true,
        titleSpacing: 0.0,
        title: Text("Let's Chat", style: TextStyle(color: Colors.white)),
        // iconTheme: IconThemeData(color: Colors.black),
        elevation: 8.0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(12.0))),
        backgroundColor: Colors.blue[700],
      ),
      drawer: drawerBody(),
      body: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 4.0),
                child: Text(
                  "Friends",
                  style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          StreamBuilder<DocumentSnapshot>(
              stream: databaseRef
                  .collection('users')
                  .document(widget.user.email)
                  .snapshots(),
              builder: (context, snapshot1) {
                if (!snapshot1.hasData) {
                  return Container(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return snapshot1.hasData
                    ? Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListView.builder(
                            itemCount: snapshot1?.data?.data['friends'].length,
                            itemBuilder: (context, index) {
                              // DocumentReference data = snapshot.data.data['friends'][index];
                              return StreamBuilder<DocumentSnapshot>(
                                stream: snapshot1.data.data['friends'][index]
                                    .snapshots(),
                                builder: (context, snapshot2) {
                                  print(snapshot2?.data?.data);
                                  return snapshot2.hasData
                                      ? Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Column(
                                            children: <Widget>[
                                              ListTile(
                                                // dense: true,
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ChatScreen(
                                                        reciverEmail: snapshot2
                                                            .data.data['email'],
                                                        reciverPhoto: snapshot2
                                                            .data.data['photo'],
                                                        reciverName: snapshot2
                                                            .data
                                                            .data['username'],
                                                        sender: widget.user,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                leading: CircleAvatar(
                                                  radius: 30.0,
                                                  backgroundImage:
                                                      Image.network(
                                                    snapshot2
                                                        .data.data['photo'],
                                                  ).image,
                                                ),
                                                title: Text(
                                                  snapshot2
                                                      .data.data['username']
                                                      .toString(),
                                                  style:
                                                      TextStyle(fontSize: 21.5),
                                                ),
                                              ),
                                              Divider(
                                                // indent: 60.0,
                                                thickness: 1.3,
                                                color: Colors.black26,
                                              )
                                            ],
                                          ),
                                        )
                                      : Container();
                                },
                              );
                            },
                          ),
                        ),
                      )
                    : Container(
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
              }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showEmailInputBox(),
        child: Center(
            child: Icon(
          Icons.person_add,
          size: 27,
        )),
        backgroundColor: Colors.blue[700],
        tooltip: "Add new friend",
      ),
    );
  }

  Widget drawerBody() {
    return Drawer(
      child: Container(
        color: Colors.cyan[400],
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 50.0,
            ),
            Container(
              padding: EdgeInsets.only(left: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  CircleAvatar(
                    radius: 35.0,
                    backgroundColor: Colors.black54,
                    backgroundImage: NetworkImage(widget.user.photoUrl),
                  ),
                  SizedBox(
                    width: 15.0,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.user.displayName,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 28.0,
                            fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8.0),
                      Text(
                        widget.user.email,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
            SizedBox(
              height: 12.0,
            ),
            Divider(
              thickness: 1,
              color: Colors.white,
            ),
            ListTile(
              onTap: _logout,
              leading: Icon(
                Icons.power_settings_new,
                color: Colors.white,
              ),
              title: Text("Sign Out",
                  style: TextStyle(fontSize: 19.0, color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
