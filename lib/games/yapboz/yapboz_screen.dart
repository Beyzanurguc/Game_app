import 'package:flutter/material.dart';

class YapbozScreen extends StatelessWidget {
  const YapbozScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yapboz')),
      body: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Yapboz Game Screen'),
            SizedBox(height: 8),
            Text(' (Puzzle Game Screen)'),
          ],
        ),
      ),
    );
  }
}
