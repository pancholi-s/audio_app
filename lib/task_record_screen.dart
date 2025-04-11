// task_record_screen.dart

import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

import 'google_drive_service.dart';

class TaskRecordScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  TaskRecordScreen({required this.task});

  @override
  _TaskRecordScreenState createState() => _TaskRecordScreenState();
}

class _TaskRecordScreenState extends State<TaskRecordScreen> {
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

    final dir = await getTemporaryDirectory();
    final taskId = widget.task['id'] ?? 'unknown';
    audioPath = '${dir.path}/$taskId.aac';

    await _recorder.openRecorder();
    isInitialized = true;
  }

  Future<void> startRecording() async {
    if (!isInitialized) return;
    await _recorder.startRecorder(toFile: audioPath);
    setState(() => isRecording = true);
  }

  Future<void> stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => isRecording = false);

    if (audioPath != null) {
      try {
        final file = File(audioPath!);
        if (await file.exists()) {
          await uploadToGoogleDrive(file, customName: '${widget.task['id']}.aac');
          await markTaskCompleted(widget.task['id']);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Uploaded & Task Marked Complete")),
          );
          Navigator.pop(context); 
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Recording file not found")),
          );
        }
      } catch (e) {
        log(e.toString());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: $e")),
        );
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
    final taskText = widget.task['text'] ?? '';
    return Scaffold(
      appBar: AppBar(title: Text('Read & Record')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(taskText, style: TextStyle(fontSize: 18)),
            SizedBox(height: 30),
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
          ],
        ),
      ),
    );
  }
}
