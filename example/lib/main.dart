import 'package:flutter/material.dart';
import 'screens/list.dart';

void main() {
  runApp(const KitchenSinks());
}

class KitchenSinks extends StatelessWidget {
  const KitchenSinks({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.purple.shade200,
      ),
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.purple.shade600,
      ),
      home: const ListKitchenSinks(),
    );
  }
}
