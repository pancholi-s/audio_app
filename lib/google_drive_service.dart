import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<void> uploadToGoogleDrive(File file, {String? customName}) async {
  final googleUser = await GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]).signIn();
  if (googleUser == null) return;

  final authHeaders = await googleUser.authHeaders;
  final client = GoogleAuthClient(authHeaders);
  final driveApi = drive.DriveApi(client);

  final fileToUpload = drive.File()
    ..name = customName ?? 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';

  await driveApi.files.create(
    fileToUpload,
    uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
  );
}

Future<drive.File?> _getReadingTasksFile(drive.DriveApi driveApi) async {
  final fileList = await driveApi.files.list(
    q: "name='reading_tasks.json' and trashed=false",
    spaces: 'drive',
  );

  return fileList.files?.isNotEmpty == true ? fileList.files!.first : null;
}

Future<List<Map<String, dynamic>>> loadReadingTasks() async {
  try {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('reading_tasks')
        .orderBy('createdAt', descending: false)
        .get();

    final tasks = querySnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'text': data['text'] ?? '',
        'isCompleted': data['isCompleted'] ?? false,
        'createdAt': data['createdAt'] ?? '',
      };
    }).toList();

    print("✅ Loaded ${tasks.length} reading tasks from Firestore");
    return tasks;
  } catch (e) {
    print("❌ Error in loadReadingTasks (Firestore): $e");
    return [];
  }
}

Future<void> _saveReadingTasks(List<Map<String, dynamic>> tasks, driveApi, fileId) async {
  final content = utf8.encode(jsonEncode(tasks));
  await driveApi.files.update(
    drive.File(),
    fileId,
    uploadMedia: drive.Media(Stream.value(content), content.length),
  );
}

Future<void> addReadingTask(String text) async {
  try {
    final taskData = {
      'text': text,
      'isCompleted': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };

    final docRef = await FirebaseFirestore.instance
        .collection('reading_tasks')
        .add(taskData);

    print("✅ Task added to Firestore with ID: ${docRef.id}");
  } catch (e) {
    print("❌ Error in addReadingTask (Firestore): $e");
  }
}

Future<void> markTaskCompleted(String taskId) async {
  try {
    await FirebaseFirestore.instance
        .collection('reading_tasks')
        .doc(taskId)
        .update({'isCompleted': true});

    print("✅ Task $taskId marked as completed in Firestore");
  } catch (e) {
    print("❌ Error marking task completed: $e");
    rethrow;
  }
}
