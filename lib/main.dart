import 'package:flutter/material.dart';
import 'package:nageclosin/screens/home_screen.dart';
import 'login_page.dart'; // Importa la nueva página

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // @override
  // Widget build(BuildContext context) {
  //   return MaterialApp(
  //     title: 'Nageclosin',
  //     theme: ThemeData(
  //       colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  //     ),
  //     home: const LoginPage(), // Mostramos la pantalla de login
  //     debugShowCheckedModeBanner: false,
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
