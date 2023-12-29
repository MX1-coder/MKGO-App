// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:fr.innoyadev.mkgodev/add/add.dart';
// import 'package:fr.innoyadev.mkgodev/cart/cart.dart';
import 'package:fr.innoyadev.mkgodev/homeScreen/Cart.dart';
import 'package:fr.innoyadev.mkgodev/homeScreen/homeScreen.dart';
import 'package:fr.innoyadev.mkgodev/notes/notes.dart';

class LandingScreen2 extends StatefulWidget {
  const LandingScreen2({super.key});

  @override
  State<LandingScreen2> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<LandingScreen2> {
  int? currentIndex;
  int myIndex = 0;
  List<Widget> widgetList = [
    HomeScreen(),
    Notes(),
    CART(),

    // Add(),
  ];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;

    if (args != null && args is int) {
      myIndex = args;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        bottomNavigationBar: BottomNavigationBar(
            selectedFontSize: 14,
            selectedLabelStyle: TextStyle(fontFamily: 'kanit'),
            unselectedLabelStyle: TextStyle(fontFamily: 'kanit'),
            backgroundColor: Colors.white,
            onTap: (index) {
              setState(() {
                myIndex = index;
              });
            },
            currentIndex: myIndex,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: Color(0xFF3954A4),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.calendar_month_outlined),
                label: 'Planning',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.messenger_outline_rounded),
                label: 'Notes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart_outlined),
                label: 'Panier',
              )
            ]),
        body: IndexedStack(
          index: myIndex,
          children: widgetList,
        ));
  }
}
