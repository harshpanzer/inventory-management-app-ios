import 'package:flutter/material.dart';
import 'package:inventoryapp/inventory_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InventoryApp());
}




class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Offline Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const InventoryScreen(), 
    );
  }
}
