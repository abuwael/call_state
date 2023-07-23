// import 'dart:isolate';
// import 'package:flutter/material.dart';
// import 'package:flutter_isolate/flutter_isolate.dart';
// import 'package:phone_state/phone_state.dart';

// void phoneStateIsolateRunner(SendPort sendPort) async {
//   PhoneState.stream.listen(
//     (phoneCall) {
//       sendPort.send(phoneCall);
//       print(phoneCall);
//     },
//   );
// }

// // void startPhoneStateIsolate() async {
// //   final isolate = await FlutterIsolate.spawn(phoneStateIsolateRunner);
// // }

// class MyWidget extends StatefulWidget {
//   const MyWidget({super.key});

//   @override
//   State<MyWidget> createState() => _MyWidgetState();
// }

// class _MyWidgetState extends State<MyWidget> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(body: Container(color: Colors.blueAccent));
//   }
// }
