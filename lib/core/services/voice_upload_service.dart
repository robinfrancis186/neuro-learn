import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class VoiceUploadService {
  static VoiceUploadService? _instance;
  static VoiceUploadService get instance => _instance!;
  
  late Dio _dio;
  late String _baseUrl;
  bool _isInitialized = false;
  
  static Future<void> initialize() async {
    _instance = VoiceUploadService._();
    await _instance!._init();
  }
  
  VoiceUploadService._();
  
  Future<void> _init() async {
    _dio = Dio();
    _baseUrl = 'http://127.0.0.1:8000'; // Backend API URL
    _isInitialized = true;
  }
  
  /// Upload a reference audio file to the backend
  Future<VoiceUploadResponse> uploadReferenceAudio(dynamic audioFile) async {
    if (!_isInitialized) throw Exception('VoiceUploadService not initialized');
    
    try {
      FormData formData;
      
      if (kIsWeb) {
        // Web platform: audioFile is Uint8List with filename
        if (audioFile is! Map<String, dynamic>) {
          throw VoiceUploadException('Invalid file data for web platform');
        }
        
        Uint8List bytes = audioFile['bytes'] as Uint8List;
        String fileName = audioFile['name'] as String;
        
        formData = FormData.fromMap({
          'reference_audio': MultipartFile.fromBytes(
            bytes,
            filename: fileName,
          ),
        });
      } else {
        // Mobile platform: audioFile is File
        if (audioFile is! File) {
          throw VoiceUploadException('Invalid file data for mobile platform');
        }
        
        String fileName = audioFile.path.split('/').last;
        formData = FormData.fromMap({
          'reference_audio': await MultipartFile.fromFile(
            audioFile.path,
            filename: fileName,
          ),
        });
      }
      
      final response = await _dio.post(
        '$_baseUrl/save-reference-audio',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return VoiceUploadResponse.fromJson(response.data);
      } else {
        throw VoiceUploadException('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      if (e is DioException) {
        throw VoiceUploadException('Network error: ${e.message}');
      }
      throw VoiceUploadException('Upload failed: $e');
    }
  }
  
  /// Pick an audio file from device storage
  Future<dynamic> pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'm4a', 'flac'],
        allowMultiple: false,
      );
      
      if (result != null) {
        PlatformFile file = result.files.single;
        
        if (kIsWeb) {
          // Web platform: return bytes and filename
          if (file.bytes != null) {
            return {
              'bytes': file.bytes!,
              'name': file.name,
              'size': file.size,
            };
          }
          return null;
        } else {
          // Mobile platform: return File object
          if (file.path != null) {
            return File(file.path!);
          }
          return null;
        }
      }
      return null;
    } catch (e) {
      throw VoiceUploadException('Failed to pick file: $e');
    }
  }
  
  /// Get supported audio formats
  List<String> get supportedFormats => ['mp3', 'wav', 'aac', 'm4a', 'flac'];
  
  /// Validate if file is a supported audio format
  bool isValidAudioFile(dynamic file) {
    if (kIsWeb) {
      if (file is Map<String, dynamic>) {
        String fileName = file['name'] as String;
        String extension = fileName.split('.').last.toLowerCase();
        return supportedFormats.contains(extension);
      }
      return false;
    } else {
      if (file is File) {
        String extension = file.path.split('.').last.toLowerCase();
        return supportedFormats.contains(extension);
      }
      return false;
    }
  }
  
  /// Get file size in MB
  double getFileSizeMB(dynamic file) {
    if (kIsWeb) {
      if (file is Map<String, dynamic>) {
        int bytes = file['size'] as int;
        return bytes / (1024 * 1024);
      }
      return 0.0;
    } else {
      if (file is File) {
        int bytes = file.lengthSync();
        return bytes / (1024 * 1024);
      }
      return 0.0;
    }
  }
}

class VoiceUploadResponse {
  final bool success;
  final String message;
  final String? path;
  
  VoiceUploadResponse({
    required this.success,
    required this.message,
    this.path,
  });
  
  factory VoiceUploadResponse.fromJson(Map<String, dynamic> json) {
    return VoiceUploadResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      path: json['path'],
    );
  }
}

class VoiceUploadException implements Exception {
  final String message;
  VoiceUploadException(this.message);
  
  @override
  String toString() => 'VoiceUploadException: $message';
} 