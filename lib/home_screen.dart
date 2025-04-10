import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'record_audio_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome!'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await signOutGoogle();
              },
              child: Text('Logout'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RecordAudioScreen()),
                );
              },
              child: Text('Record Audio'),
            ),
          ],
        ),
      ),
    );
  }
}
