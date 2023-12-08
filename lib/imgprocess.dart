import 'dart:io';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:stayfitdemo/secureStorage.dart';

const _clientId = "142489212594-mkdbqh3fich8cm6qjoo4aannoucfaqtn.apps.googleusercontent.com";
const _scopes = ['https://www.googleapis.com/auth/drive.file'];

class GoogleDrive {
  final storage = SecureStorage();

  Future<http.Client> getHttpClient() async {
    try {
      var credentials = await storage.getCredentials();
      if (credentials == null) {
        // Needs user authentication
        var authClient = await clientViaUserConsent(
          ClientId(_clientId),
          _scopes,
              (url) {
            // Open the URL in the browser or WebView
            print("Please go to the following URL and grant access:");
            print(url);
            // Open the URL in the default browser (may not work on all platforms)
            // launch(url);
          },
        );

        // Save the credentials
        await storage.saveCredentials(
          authClient.credentials.accessToken,
          authClient.credentials.refreshToken!,
        );

        return authClient;
      } else {
        // Already authenticated with user consent
        return authenticatedClient(
          http.Client(),
          AccessCredentials(
            AccessToken(credentials["type"], credentials["data"],
                DateTime.tryParse(credentials["expiry"])!),
            credentials["refreshToken"],
            _scopes,
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Error getting HTTP client: $e');
      print('Stack trace: $stackTrace');
      rethrow; // Rethrow the exception to ensure it's propagated
    }
  }

  Future<String?> _getFolderId(ga.DriveApi driveApi) async {
    final mimeType = "application/vnd.google-apps.folder";
    String folderName = "dtheek";

    try {
      final found = await driveApi.files.list(
        q: "mimeType = '$mimeType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found.files;

      if (files != null && files.isNotEmpty) {
        return files.first.id;
      }

      // Create a folder
      ga.File folder = ga.File();
      folder.name = folderName;
      folder.mimeType = mimeType;
      final folderCreation = await driveApi.files.create(folder);
      print("Folder ID: ${folderCreation.id}");

      return folderCreation.id;
    } catch (e) {
      print('Error during folder ID retrieval or creation: $e');
      return null;
    }
  }

  uploadFileToGoogleDrive(File file) async {
    try {
      var client = await getHttpClient();
      var drive = ga.DriveApi(client);
      String? folderId = await _getFolderId(drive);

      if (folderId == null) {
        print("Error: Unable to retrieve or create folder ID");
      } else {
        ga.File fileToUpload = ga.File();
        fileToUpload.parents = [folderId];
        fileToUpload.name = p.basename(file.absolute.path);

        var response = await drive.files.create(
          fileToUpload,
          uploadMedia: ga.Media(file.openRead(), file.lengthSync()),
        );

        print('File uploaded successfully! File ID: ${response.id}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      print('Current working directory: ${Directory.current.path}');
    }
  }
}
