import 'package:flutter/material.dart';
import 'screens/route_planner_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Route Planner - Dijkstra Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const RoutePlannerScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
