import 'dart:developer';
import 'dart:io';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();
  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

Future<void> uploadToGoogleDrive(File file) async {
  log('Uploading to Google Drive: ${file.path}');
  final googleUser = await GoogleSignIn.standard(scopes: [drive.DriveApi.driveFileScope]).signIn();
  if (googleUser == null) return;

  final authHeaders = await googleUser.authHeaders;
  final client = GoogleAuthClient(authHeaders);
  final driveApi = drive.DriveApi(client);

  final fileToUpload = drive.File()
    ..name = 'audio_${DateTime.now().millisecondsSinceEpoch}.aac';

  await driveApi.files.create(
    fileToUpload,
    uploadMedia: drive.Media(file.openRead(), file.lengthSync()),
  );
}