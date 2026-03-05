import 'package:flutter/material.dart';
import 'SplashScreen/splashscreen.dart';


void main()  {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
   
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'KyU_Robotics',
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => "Title Generated",
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const Splashscreen(), 
    );
  }
}