import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

class EvolutionApiService extends GetxService {
  late Dio _dio;
  
  static const String baseUrl = "https://wa.pro26.in";
  static const String apiKey = "muhammedshabeerop";
  static const String instanceName = "muhammed shabeer op";
  
  // Group JID for the provided link: https://chat.whatsapp.com/BvmPf8rB0p7C7H0p3GVoiW
  // Note: Evolution API usually requires the JID (e.g. 1234567890@g.us)
  // If we only have the invite code, we might need an endpoint to join or resolve it.
  // For now, we'll use a placeholder or assume the user will provide the JID if needed.
  // Many Evolution API versions allow sending to an invite code directly or resolving it.
  static const String groupInviteCode = "BvmPf8rB0p7C7H0p3GVoiW";

  Future<EvolutionApiService> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'apikey': apiKey,
        'Content-Type': 'application/json',
      },
    ));
    return this;
  }

  // Resolve Group JID from Invite Code
  Future<String?> getGroupJidFromInvite(String inviteCode) async {
    try {
      final response = await _dio.get('/group/inviteInfo/$instanceName?inviteCode=$inviteCode');
      if (response.data != null && response.data['subject'] != null) {
         return response.data['id']; // This is the JID
      }
      return null;
    } catch (e) {
      print('Evolution API Invite Error: $e');
      return null;
    }
  }

  // Send text message to a number or group JID
  Future<Response> sendMessage(String destination, String message) async {
    try {
      final response = await _dio.post(
        '/message/sendText/$instanceName',
        data: {
          'number': destination,
          'text': message,
        },
      );
      return response;
    } catch (e) {
      print('Evolution API Error: $e');
      rethrow;
    }
  }

  // Send audio file to a number or group JID
  Future<Response> sendAudio(String destination, String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found: $filePath");
      }

      final bytes = await file.readAsBytes();
      final base64Audio = base64Encode(bytes);

      final response = await _dio.post(
        '/message/sendWhatsAppAudio/$instanceName',
        data: {
          'number': destination,
          'audio': base64Audio,
          'options': {
            'delay': 1200,
            'presence': 'composing',
          }
        },
      );
      return response;
    } catch (e) {
      print('Evolution API Audio Error: $e');
      rethrow;
    }
  }

  // Send media/file (document) to a number or group JID
  Future<Response> sendDocument(String destination, String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception("File not found: $filePath");
      }

      final bytes = await file.readAsBytes();
      final base64File = base64Encode(bytes);

      final response = await _dio.post(
        '/message/sendMedia/$instanceName',
        data: {
          'number': destination,
          'media': base64File,
          'mediaType': 'document',
          'fileName': fileName,
          'caption': 'Audio Document: $fileName',
        },
      );
      return response;
    } catch (e) {
      print('Evolution API Document Error: $e');
      rethrow;
    }
  }

  // Check instance status
  Future<Response> getInstanceStatus() async {
    try {
      final response = await _dio.get('/instance/connectionState/$instanceName');
      return response;
    } catch (e) {
      print('Evolution API Error: $e');
      rethrow;
    }
  }
}
