import 'package:flutter/material.dart';

void main() {
  // Arranca la app
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(body: Center(child: Text('2048'))),
  ));
}
