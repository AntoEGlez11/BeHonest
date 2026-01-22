import 'package:flutter/material.dart';
import '../../map/presentation/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MapScreen(),
    );
  }
}

