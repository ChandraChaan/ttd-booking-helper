import 'package:flutter/material.dart';

import 'src/home_page.dart';
import 'src/look.dart';
import 'src/state.dart';

void main() {
  final state = AppState()..load();
  runApp(TtdApp(state: state));
}

class TtdApp extends StatelessWidget {
  const TtdApp({super.key, required this.state, this.clock});

  final AppState state;
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TTD Booking Helper',
      debugShowCheckedModeBanner: false,
      theme: Look.light.theme(Brightness.light),
      darkTheme: Look.dark.theme(Brightness.dark),
      home: HomePage(state: state, clock: clock),
    );
  }
}
