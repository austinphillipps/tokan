// lib/shared/interface/adaptive_home_screen.dart

import 'package:flutter/material.dart';

import 'interface.dart';
import 'mobile_interface.dart';

class AdaptiveHomeScreen extends StatelessWidget {
  const AdaptiveHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const MobileHomeScreen();
    }
    return const HomeScreen();
  }
}