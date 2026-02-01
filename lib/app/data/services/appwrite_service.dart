import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import '../models/recording_model.dart';
import 'storage_service.dart';

class AppwriteService extends GetxService {
  late Client client;
  late Account account;
  late Databases databases;
  late Storage storage;

  // Constants from appwrite.config.json
  static const String endpoint = "https://fra.cloud.appwrite.io/v1";
  static const String projectId = "soundscape";
  static const String databaseId = "68da4b6900256869e751";
  static const String bucketId = "68da4c5b000c0e3e788d";
  
  static const String recordingsCollectionId = "recordings";
  static const String detectionsCollectionId = "detections";
  static const String usersCollectionId = "users";

  String? _userId;
  bool _userDocExists = false;
  
  final isLoggedIn = false.obs;
  final currentUser = Rxn<models.User>();

  Future<AppwriteService> init() async {
    client = Client()
        .setEndpoint(endpoint)
        .setProject(projectId);
        
    account = Account(client);
    databases = Databases(client);
    storage = Storage(client);

    await refreshAuthStatus();
    
    return this;
  }

  @override
  void onReady() {
    super.onReady();
    refreshAuthStatus();
  }

  Future<void> refreshAuthStatus() async {
    try {
      final user = await account.get();
      _userId = user.$id;
      currentUser.value = user;
      isLoggedIn.value = true;
      await _initUserAndDoc();
    } catch (_) {
      _userId = null;
      currentUser.value = null;
      isLoggedIn.value = false;
      _userDocExists = false;
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await account.createEmailPasswordSession(email: email, password: password);
      await refreshAuthStatus();
    } catch (e) {
      throw Exception("Login failed: ${e.toString()}");
    }
  }

  Future<void> signup(String email, String password, String name) async {
    try {
      await account.create(userId: ID.unique(), email: email, password: password, name: name);
    } catch (e) {
      throw Exception("Signup failed: ${e.toString()}");
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSession(sessionId: 'current');
      await refreshAuthStatus();
    } catch (_) {
      // Force reset even if deleteSession fails (e.g. session already gone)
      _userId = null;
      currentUser.value = null;
      isLoggedIn.value = false;
      _userDocExists = false;
    }
  }

  Future<models.User?> getCurrentUser() async {
    try {
      return await account.get();
    } catch (_) {
      return null;
    }
  }

  Future<List<Recording>> getUserRecordings() async {
    if (_userId == null) return [];

    try {
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: recordingsCollectionId,
        queries: [
          Query.orderDesc('\$createdAt'),
        ]
      );

      List<Recording> recordings = [];

      for (var doc in result.documents) {
        final data = doc.data;
        String fileId = data['s3key'];
        String path = storage.getFileView(bucketId: bucketId, fileId: fileId).toString();

        Recording rec = Recording(
          id: doc.$id,
          path: path,
          timestamp: DateTime.parse(doc.$createdAt),
          duration: Duration(seconds: data['duration'] ?? 0), 
          latitude: (data['latitude'] as num?)?.toDouble(),
          longitude: (data['longitude'] as num?)?.toDouble(),
          status: (data['status'] as String?)?.toLowerCase() ?? 'pending',
        );

        try {
           final detResult = await databases.listDocuments(
             databaseId: databaseId,
             collectionId: detectionsCollectionId,
             queries: [ Query.equal('recordings', doc.$id) ]
           );
           
           if (detResult.documents.isNotEmpty) {
             final det = detResult.documents.first;
             final names = det.data['scientificName'] as List?;
             if (names != null && names.isNotEmpty) {
               rec.commonName = names.first.toString();
             }
             final confs = det.data['confidenceLevel'] as List?;
             if (confs != null && confs.isNotEmpty) {
               rec.confidence = (confs.first as num).toDouble();
             }
             rec.status = 'processed';
           }
        } catch (e) {
          print("Appwrite: Error fetching detections for ${doc.$id}: $e");
        }

        recordings.add(rec);
      }
      return recordings;

    } catch (e) {
      print("Appwrite: Error fetching recordings: $e");
      return [];
    }
  }

  Future<void> _initUserAndDoc() async {
    try {
      final user = await account.get();
      _userId = user.$id;
      
      // Ensure user document exists in 'users' collection for relationship
      try {
        await databases.getDocument(
          databaseId: databaseId,
          collectionId: usersCollectionId,
          documentId: _userId!,
        );
        _userDocExists = true;
      } catch (e) {
        // If not found (404), create it
        if (e is AppwriteException && e.code == 404) {
          try {
            await databases.createDocument(
              databaseId: databaseId,
              collectionId: usersCollectionId,
              documentId: _userId!,
              data: {
                'email': user.email.isNotEmpty ? user.email : null,
                'role': 'SCOUT', // Default role
              },
            );
            _userDocExists = true;
            print("Appwrite: Created user document for $_userId");
          } catch (createError) {
             print("Appwrite: Could not create user doc (likely permissions). Continuing without linking. Error: $createError");
             _userDocExists = false;
          }
        } else {
          print("Appwrite: Error checking user doc: $e");
          _userDocExists = false;
        }
      }
    } catch (e) {
      print("Appwrite: Error getting account: $e");
      rethrow;
    }
  }

  Future<void> uploadRecording(Recording recording) async {
    if (_userId == null) {
      throw Exception("User not authenticated. Please login.");
    }

    try {
      final file = File(recording.path);
      if (!await file.exists()) {
        throw Exception("File not found at ${recording.path}");
      }

      // 1. Upload File
      final upload = await storage.createFile(
        bucketId: bucketId,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: recording.path, filename: p.basename(recording.path)),
      );

      // 2. Create Document
      final doc = await databases.createDocument(
        databaseId: databaseId,
        collectionId: recordingsCollectionId,
        documentId: recording.id, 
        data: {
          's3key': upload.$id,
          'status': 'QUEUED',
          'latitude': recording.latitude,
          'longitude': recording.longitude,
          'duration': recording.duration.inSeconds,
          'user-id': _userDocExists ? _userId : null, 
        },
        permissions: [
          Permission.read(Role.user(_userId!)),
          Permission.update(Role.user(_userId!)),
          Permission.delete(Role.user(_userId!)),
        ],
      );
      
      // Update local status
      recording.status = 'uploaded';
      Get.find<StorageService>().updateRecording(recording);
      
      if(Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
           const SnackBar(content: Text("Upload Successful! Analyzing..."), backgroundColor: Colors.teal)
        );
      }

      // 3. Listen for updates
      _listenForAnalysis(doc.$id, recording);

    } catch (e) {
      _handleUploadError(recording, e.toString());
    }
  }

  void _handleUploadError(Recording recording, String error) {
    print("Upload failed: $error");
    recording.status = 'failed';
    Get.find<StorageService>().updateRecording(recording);
    
    if(Get.context != null) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
         SnackBar(content: Text("Upload Failed: $error"), backgroundColor: Colors.red)
      );
    }
  }

  void _listenForAnalysis(String documentId, Recording recording) {
    final realtime = Realtime(client);
    final subscription = realtime.subscribe([
      'databases.$databaseId.collections.$recordingsCollectionId.documents.$documentId'
    ]);

    subscription.stream.listen((response) {
      if (response.payload.isNotEmpty) {
        final data = response.payload;
        final status = data['status'];
        
        if (status == 'COMPLETED') {
          _fetchDetections(documentId, recording);
          // Optional: Cancel subscription if we could store it
        } else if (status == 'FAILED') {
           recording.status = 'failed';
           Get.find<StorageService>().updateRecording(recording);
        }
      }
    });
  }

  Future<void> _fetchDetections(String recordingDocId, Recording recording) async {
    try {
      final result = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: detectionsCollectionId,
        queries: [
          Query.equal('recordings', recordingDocId)
        ]
      );

      if (result.documents.isNotEmpty) {
        final detection = result.documents.first;
        final scientificNames = detection.data['scientificName'] as List<dynamic>?;
        final confidence = detection.data['confidenceLevel'] as List<dynamic>?;

        if (scientificNames != null && scientificNames.isNotEmpty) {
          recording.commonName = scientificNames.first.toString();
          recording.status = 'processed';
          
          if(confidence != null && confidence.isNotEmpty) {
             // Handle Int to Double conversion
             final confVal = confidence.first;
             if (confVal is int) {
               recording.confidence = confVal.toDouble();
             } else if (confVal is double) {
               recording.confidence = confVal;
             }
          }
          
          await Get.find<StorageService>().updateRecording(recording);
          
          if(Get.context != null) {
             ScaffoldMessenger.of(Get.context!).showSnackBar(
               SnackBar(
                 content: Text("Analysis Complete: Identified ${recording.commonName}"), 
                 backgroundColor: Colors.green,
                 duration: const Duration(seconds: 4),
               )
             );
          }
        }
      }
    } catch (e) {
      print("Error fetching detections: $e");
    }
  }

  Future<void> deleteRecording(String docId) async {
    try {
      // 1. Get document to find fileId
      models.Document doc;
      try {
        doc = await databases.getDocument(
          databaseId: databaseId,
          collectionId: recordingsCollectionId,
          documentId: docId,
        );
      } on AppwriteException catch (e) {
        if (e.code == 404) {
          print("Appwrite: Document already gone or never uploaded.");
          return; // Already deleted or doesn't exist
        }
        rethrow;
      }
      
      final fileId = doc.data['s3key'];
      
      // 2. Delete File (if exists)
      if (fileId != null) {
        try {
          await storage.deleteFile(bucketId: bucketId, fileId: fileId);
        } catch (e) {
          print("Appwrite: Error deleting file (might be already gone): $e");
        }
      }

      // 3. Delete Document
      try {
        await databases.deleteDocument(
          databaseId: databaseId,
          collectionId: recordingsCollectionId,
          documentId: docId,
        );
      } on AppwriteException catch (e) {
        if (e.code != 404) rethrow;
      }
      
    } catch (e) {
      print("Appwrite: Error deleting recording: $e");
      rethrow; // Re-throw to let controller handle it
    }
  }

  Future<void> updateRecordingMetadata(String docId, String newName) async {
    // Attempt to update 'scientificName' in related detection
    try {
       final result = await databases.listDocuments(
         databaseId: databaseId,
         collectionId: detectionsCollectionId,
         queries: [ Query.equal('recordings', docId) ]
       );

       if (result.documents.isNotEmpty) {
         final detId = result.documents.first.$id;
         await databases.updateDocument(
           databaseId: databaseId,
           collectionId: detectionsCollectionId,
           documentId: detId,
           data: {
             'scientificName': [newName] // Overwrite array with single new name
           }
         );
       }
    } catch (e) {
      print("Appwrite: Error updating metadata: $e");
    }
  }
}
