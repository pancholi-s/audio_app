// record_audio_screen.dart
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'google_drive_service.dart';

class RecordAudioScreen extends StatefulWidget {
  @override
  _RecordAudioScreenState createState() => _RecordAudioScreenState();
}

class _RecordAudioScreenState extends State<RecordAudioScreen> {
  final _recorder = FlutterSoundRecorder();
  bool isRecording = false;
  bool isInitialized = false;
  String? audioPath;

  @override
  void initState() {
    super.initState();
    initRecorder();
  }

  Future<void> initRecorder() async {
    await Permission.microphone.request();
    await Permission.storage.request();

    final downloadsDir = Directory('/storage/emulated/0/Download');
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    audioPath = '${downloadsDir.path}/audio_$timestamp.aac';

    await _recorder.openRecorder();
    isInitialized = true;
  }

  Future<void> startRecording() async {
    await _recorder.startRecorder(toFile: audioPath);
    setState(() => isRecording = true);
  }

  // Future<void> stopRecording() async {
  //   await _recorder.stopRecorder();
  //   setState(() => isRecording = false);
  // }

  Future<void> stopRecording() async {
  await _recorder.stopRecorder();
  setState(() => isRecording = false);

    if (audioPath != null) {
      try {
        final file = File(audioPath!);
        if (await file.exists()) {
          await uploadToGoogleDrive(file);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Uploaded to Google Drive")),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Recording file not found")),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
        log(e.toString());
      }
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Record Audio')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecording ? Icons.mic : Icons.mic_none,
              size: 80,
              color: isRecording ? Colors.red : Colors.black,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isRecording ? stopRecording : startRecording,
              child: Text(isRecording ? 'Stop Recording' : 'Start Recording'),
            ),
            if (audioPath != null && !isRecording)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Text('Saved to: $audioPath'),
              ),
          ],
        ),
      ),
    );
  }
}
