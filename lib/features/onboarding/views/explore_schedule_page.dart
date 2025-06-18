import 'package:flutter/material.dart';

import '../../../shared/interface/interface.dart';
import '../../../utils/tab_launcher.dart';

class ExploreSchedulePage extends StatelessWidget {
  const ExploreSchedulePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Que souhaitez-vous faire ?')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choisissez comment continuer :',
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  );
                },
                child: const Text('Continuer la découverte'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  openTab('https://example.com/rendezvous');
                },
                child: const Text('Prendre rendez-vous'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
