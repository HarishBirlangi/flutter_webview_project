import 'package:flutter/material.dart';
import 'package:flutter_app_inappwebview/inappwebview_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const InAppWebPage(initialUrl: "http://192.168.69.11:5000/"),
      debugShowCheckedModeBanner: false,
    );
  }
}
