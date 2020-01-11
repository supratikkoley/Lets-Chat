import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ChatScreen extends StatefulWidget {
  // final DocumentReference reciver;
  final String reciverPhoto;
  final FirebaseUser sender;
  final String reciverName;
  final String reciverEmail;

  ChatScreen({
    @required this.reciverPhoto,
    @required this.reciverName,
    @required this.reciverEmail,
    @required this.sender,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  TextEditingController _msgController = TextEditingController();

  // List<Map<String, dynamic>> _msgList = [];
  final databaseRef = Firestore.instance;
  bool iconChanged = false;

  _sendMessage(String message) async {
    //sender's chat update
    await databaseRef
        .collection('users')
        .document(widget.sender.email)
        .collection(widget.reciverEmail)
        .add({
      'msg': message,
      'sender': widget.sender.email,
      'reciver': widget.reciverEmail,
      'time': DateTime.now(),
      'sent': false
    }).then((sendermsg) {
      //reciver's chat update
      databaseRef
          .collection('users')
          .document(widget.reciverEmail)
          .collection(widget.sender.email)
          .add({
        'msg': message,
        'sender': widget.sender.email,
        'reciver': widget.reciverEmail,
        'time': DateTime.now(),
      }).then((_) {
        databaseRef
            .collection('users')
            .document(widget.sender.email)
            .collection(widget.reciverEmail)
            .document(sendermsg.documentID)
            .updateData({
          'sent': true,
        });
      }).catchError((e) {
        print(e);
      });
    });
  }

  String dateFormat(DateTime date) {
    if (date.hour < 10 && date.minute < 10) {
      return '0' + date.hour.toString() + ':' + '0' + date.minute.toString();
    } else if (date.hour < 10) {
      return '0' + date.hour.toString() + ':' + date.minute.toString();
    } else if (date.minute < 10)
      return date.hour.toString() + ':' + '0' + date.minute.toString();
    else
      return date.hour.toString() + ':' + date.minute.toString();
  }

  @override
  void initState() {
    _msgController.addListener(() {
      print(_msgController.text);
      if (_msgController.text != null && _msgController.text != '') {
        setState(() {
          iconChanged = true;
        });
      }
      if (_msgController.text == null || _msgController.text == '') {
        setState(() {
          iconChanged = false;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0.0,
        backgroundColor: Colors.blue[700],
        title: Row(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                  )),
              child: CircleAvatar(
                backgroundImage: NetworkImage(widget.reciverPhoto),
              ),
            ),
            SizedBox(width: 10.0),
            Text(widget.reciverName),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: databaseRef
              .collection('users')
              .document(widget.sender.email)
              .collection(widget.reciverEmail)
              .orderBy('time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            return snapshot.hasData
                ? Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Padding(
                            padding: MediaQuery.of(context).viewInsets,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: ListView.builder(
                                reverse: true,
                                itemCount: snapshot
                                    .data.documents.length, //_msgList.length,
                                itemBuilder: (context, index) {
                                  Timestamp timestamp =
                                      snapshot.data.documents[index]['time'];
                                  DateTime date =
                                      DateTime.fromMicrosecondsSinceEpoch(
                                          timestamp.microsecondsSinceEpoch);
                                  print(date.minute);
                                  return chatTextCard(
                                    snapshot.data.documents[index]['msg'],
                                    snapshot.data.documents[index]['sender'] ==
                                            widget.sender.email
                                        ? 1
                                        : 2,
                                    date,
                                    snapshot.data.documents[index]['sent'],
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Expanded(child: messageInputBox()),
                            Card(
                              elevation: 15.0,
                              shape: CircleBorder(),
                              color: Colors.blue[700],
                              child: IconButton(
                                // splashColor: Colors.blue,
                                padding: EdgeInsets.all(0.0),
                                icon: iconChanged
                                    ? Icon(Icons.send)
                                    : Icon(Icons.mic),
                                color: Colors.white,
                                onPressed: () {
                                  if (_msgController.text != null &&
                                      _msgController.text != '' &&
                                      _msgController.text.trim() != '') {
                                    _sendMessage(_msgController.text);
                                    print("Sent: ${_msgController.text}");
                                    _msgController.clear();
                                  }
                                },
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
          }),
    );
  }

  Widget chatTextCard(String text, int type, DateTime date, bool sent) {
    /// type: sender or reciver
    /// sender => 1 and reciver => 2
    return Container(
      child: Row(
        mainAxisAlignment:
            type == 1 ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Card(
            semanticContainer: true,
            elevation: 5.0,
            color: type == 1 ? Colors.blue[700] : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 10.0),
                    child: Text(
                      text,
                      maxLines: null,
                      style: TextStyle(
                          fontSize: 18.0,
                          color: type == 1 ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 4.0, bottom: 4.0),
                          child: Text(
                            dateFormat(date),
                            style: TextStyle(
                                color:
                                    type == 1 ? Colors.blue[100] : Colors.grey),
                          ),
                        ),
                        type == 1
                            ? Padding(
                                padding: const EdgeInsets.only(
                                    right: 4.0, bottom: 4.0),
                                child: sent == null || sent == false
                                    ? Icon(
                                        Icons.watch_later,
                                        color: type == 1
                                            ? Colors.blue[100]
                                            : Colors.grey,
                                        size: 13.0,
                                      )
                                    : Icon(
                                        Icons.check,
                                        color: Colors.greenAccent,
                                        size: 15.0,
                                      ),
                              )
                            : Container()
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget messageInputBox() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        elevation: 6.0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              flex: iconChanged ? 5 : 4,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: 150.0,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 18.0, right: 8.0),
                  child: TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: _msgController,
                    onEditingComplete: () {
                      if (_msgController.text != null &&
                          _msgController.text != '' &&
                          _msgController.text.trim() != '') {
                        _sendMessage(_msgController.text);
                        print("Sent: ${_msgController.text}");
                        _msgController.clear();
                      }
                    },
                    onChanged: (text) {
                      print(text);
                    },
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.send,
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 19),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Type your message",
                    ),
                    // autofocus: true,
                  ),
                ),
              ),
            ),
            Expanded(
              flex: iconChanged ? 1 : 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.attach_file, color: Colors.black54),
                    // SizedBox(width: 5.0,),
                    AnimatedContainer(
                      duration: Duration(milliseconds: 5000),
                      child: iconChanged
                          ? Container()
                          : Padding(
                              padding:
                                  const EdgeInsets.only(right: 8.0, left: 15.0),
                              child:
                                  Icon(Icons.camera_alt, color: Colors.black54),
                            ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
