import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flash_chat/constants.dart';
import 'package:flash_chat/morse/tilt_handler.dart';
import 'package:flash_chat/morse/translator.dart';
import 'package:flutter/material.dart';
import 'package:sensors/sensors.dart';

import '../actions.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;
String currentUser;
int prevMessagesLength;
final _translator = new Translator();
bool sendMorse = false;
bool receiveMorse = false;
String textToSend = '';
String morseToSend = '';

Stream<String> receivedNewMessageStream;

void vibrateReceivedMessage(String morseReceived) {
  morseReceived.split('').forEach((e) {
    if (e == '-') {
      longVibrate();
    } else if (e == '.') {
      shortVibrate();
    } else if (e == '/') {
      wordEnd();
    } else {
      letterEnd();
    }
  });
}

class ChatScreen extends StatefulWidget {
  static const String id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<StreamSubscription<dynamic>> _streamSubscriptions =
      <StreamSubscription<dynamic>>[];
  MessagesStream messagesStream;

  final messageTextController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _tiltHandler = new TiltHandler();

  String morseReceived = ' ';
  String calibrationTimeDisplay = 'START';

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        currentUser = loggedInUser.email;
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();

    getCurrentUser();

    _streamSubscriptions.add(gyroscopeEvents.listen((GyroscopeEvent event) {
      if (_tiltHandler.isCalibrating()) {
        _tiltHandler.calibrate(event.x);
        setState(() {
          calibrationTimeDisplay = _tiltHandler.getTimeDisplay();
        });
      } else if (sendMorse) {
        setState(() {
          _tiltHandler.updateTyping(event.x);
          morseToSend = _tiltHandler.getTiltValues();
          textToSend = _translator.textOf(morseToSend);
          messageTextController.text = textToSend;
        });
      }
    }));

    _streamSubscriptions
        .add(accelerometerEvents.listen((AccelerometerEvent event) {
      if (sendMorse) {
        setState(() {
          _tiltHandler.updateBackspace(event.x);
          morseToSend = _tiltHandler.getTiltValues();
          textToSend = _translator.textOf(morseToSend);
          messageTextController.text = textToSend;
        });
      }
    }));

    messagesStream = MessagesStream();

    receivedNewMessageStream.listen((message) {
      setState(() {
        morseReceived = message;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    for (StreamSubscription<dynamic> subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('MORSEnger'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            messagesStream,
            Container(
              decoration: kMorseContainerDecoration,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('MORSE Calibrate'),
                  FlatButton(
                    child: Text(calibrationTimeDisplay),
                    onPressed: () {
                      setState(() {
                        _tiltHandler.startCalibrate();
                      });
                    },
                  ),
                  Expanded(child: Text('')),
                ],
              ),
            ),
            Container(
              decoration: kMorseContainerDecoration,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('MORSE Send'),
                  FlatButton(
                    child: Text(sendMorse ? 'ON' : 'OFF'),
                    onPressed: () {
                      setState(() {
                        sendMorse = !sendMorse;
                      });
                    },
                  ),
                  Expanded(child: Text(morseToSend)),
                ],
              ),
            ),
            Container(
              decoration: kMorseContainerDecoration,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text('MORSE Receive'),
                  FlatButton(
                      child: Text(receiveMorse ? 'ON' : 'OFF'),
                      onPressed: () {
                        setState(() {
                          receiveMorse = !receiveMorse;
                        });
                      }),
                  Expanded(child: Text(morseReceived)),
                ],
              ),
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: messageTextController,
                      onChanged: (value) {
                        textToSend = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      _firestore.collection('messages').add({
                        'text': textToSend,
                        'sender': loggedInUser.email,
                      });
                      messageTextController.clear();
                      _tiltHandler.reset();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final StreamController<String> receivedNewMessageController =
      StreamController<String>();

  MessagesStream() {
    receivedNewMessageStream = receivedNewMessageController.stream;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.lightBlueAccent,
            ),
          );
        }
        final messages = snapshot.data.documents.reversed;
        List<MessageBubble> messageBubbles = [];
        for (int m = 0; m < messages.length; m++) {
          final message = messages.elementAt(m);
          final messageText = message.data['text'];
          final messageSender = message.data['sender'];
          final isMe = currentUser == messageSender;

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageText,
            isMe: isMe,
          );
          messageBubbles.add(messageBubble);
          if (prevMessagesLength != null &&
              receiveMorse &&
              !isMe &&
              m < messages.length - prevMessagesLength) {
            String morseReceived = _translator.morseOf(messageText);
            receivedNewMessageController.add(morseReceived);
            vibrateReceivedMessage(morseReceived);
          }
        }
        prevMessagesLength = messages.length;
        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble({this.sender, this.text, this.isMe});

  final String sender;
  final String text;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 12.0,
              color: Colors.black54,
            ),
          ),
          Material(
            borderRadius: isMe
                ? BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0))
                : BorderRadius.only(
                    bottomLeft: Radius.circular(30.0),
                    bottomRight: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
