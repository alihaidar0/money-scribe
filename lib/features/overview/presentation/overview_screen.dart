import 'package:flutter/material.dart';

class OverviewScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Overview')),
      body: const Center(child: Text('Nothing here yet')),
    );
  }
}
