import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    // home: Text("hey ninjas!"), 
    home: Scaffold(
      appBar: AppBar(
        title: Text('my first app', style: TextStyle()),
        centerTitle: true,
        backgroundColor: Colors.blue[600],
      ),
      body: Center(child: Text("henshin", style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, letterSpacing: 2.0, color: Colors.grey[600], fontFamily: 'IndieFlower')),
      ),
      floatingActionButton: FloatingActionButton(
        child: Text('click'),
        onPressed: () {
        },
        backgroundColor: Colors.blue[600],
      ),
    ),
  ));
}

