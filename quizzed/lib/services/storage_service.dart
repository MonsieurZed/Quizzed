import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path_lib;
import 'package:quizzed/services/logging_service.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LoggingService _logger = LoggingService();

  // Base storage references
  final Reference _imagesRef;
  final Reference _audioRef;
  final Reference _videoRef;

  StorageService()
    : _imagesRef = FirebaseStorage.instance.ref().child('images'),
      _audioRef = FirebaseStorage.instance.ref().child('audio'),
      _videoRef = FirebaseStorage.instance.ref().child('video');

  // Upload an image file
  Future<String> uploadImage(File file, String questionId) async {
    try {
      _logger.logInfo(
        'Uploading image for question: $questionId',
        'StorageService.uploadImage',
      );
      // Compress the image before uploading if it's not on web
      File imageToUpload = file;
      if (!kIsWeb) {
        _logger.logDebug(
          'Attempting to compress image on mobile device',
          'StorageService.uploadImage',
        );
        final compressedImage = await _compressImage(file);
        if (compressedImage != null) {
          imageToUpload = compressedImage;
          _logger.logDebug(
            'Image compressed successfully',
            'StorageService.uploadImage',
          );
        } else {
          _logger.logWarning(
            'Image compression failed, using original image',
            'StorageService.uploadImage',
          );
        }
      }

      // Generate a unique filename
      final String fileName =
          '${questionId}_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(file.path)}';
      final Reference ref = _imagesRef.child(fileName);

      // Upload the image
      UploadTask uploadTask;
      if (kIsWeb) {
        // For web platform
        _logger.logDebug(
          'Uploading image as bytes (web platform)',
          'StorageService.uploadImage',
        );
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        // For mobile platforms
        _logger.logDebug(
          'Uploading image as file (mobile platform)',
          'StorageService.uploadImage',
        );
        uploadTask = ref.putFile(imageToUpload);
      }

      // Wait for the upload to complete
      await uploadTask;

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.logInfo(
        'Image uploaded successfully: $fileName',
        'StorageService.uploadImage',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error uploading image',
        e,
        stackTrace,
        'StorageService.uploadImage',
      );
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  // Upload an audio file
  Future<String> uploadAudio(File file, String questionId) async {
    try {
      _logger.logInfo(
        'Uploading audio for question: $questionId',
        'StorageService.uploadAudio',
      );
      // Generate a unique filename
      final String fileName =
          '${questionId}_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(file.path)}';
      final Reference ref = _audioRef.child(fileName);

      // Upload the audio file
      UploadTask uploadTask;
      if (kIsWeb) {
        _logger.logDebug(
          'Uploading audio as bytes (web platform)',
          'StorageService.uploadAudio',
        );
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        _logger.logDebug(
          'Uploading audio as file (mobile platform)',
          'StorageService.uploadAudio',
        );
        uploadTask = ref.putFile(file);
      }

      // Wait for the upload to complete
      await uploadTask;

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.logInfo(
        'Audio uploaded successfully: $fileName',
        'StorageService.uploadAudio',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error uploading audio',
        e,
        stackTrace,
        'StorageService.uploadAudio',
      );
      debugPrint('Error uploading audio: $e');
      rethrow;
    }
  }

  // Upload a video file
  Future<String> uploadVideo(File file, String questionId) async {
    try {
      _logger.logInfo(
        'Uploading video for question: $questionId',
        'StorageService.uploadVideo',
      );
      // Generate a unique filename
      final String fileName =
          '${questionId}_${DateTime.now().millisecondsSinceEpoch}${path_lib.extension(file.path)}';
      final Reference ref = _videoRef.child(fileName);

      // Upload the video file
      UploadTask uploadTask;
      if (kIsWeb) {
        _logger.logDebug(
          'Uploading video as bytes (web platform)',
          'StorageService.uploadVideo',
        );
        uploadTask = ref.putData(await file.readAsBytes());
      } else {
        _logger.logDebug(
          'Uploading video as file (mobile platform)',
          'StorageService.uploadVideo',
        );
        uploadTask = ref.putFile(file);
      }

      // Wait for the upload to complete
      await uploadTask;

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.logInfo(
        'Video uploaded successfully: $fileName',
        'StorageService.uploadVideo',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error uploading video',
        e,
        stackTrace,
        'StorageService.uploadVideo',
      );
      debugPrint('Error uploading video: $e');
      rethrow;
    }
  }

  // Upload a web-based Uint8List (for Web platform)
  Future<String> uploadBytes(
    Uint8List bytes,
    String mediaType,
    String questionId,
    String extension,
  ) async {
    try {
      _logger.logInfo(
        'Uploading bytes as $mediaType for question: $questionId',
        'StorageService.uploadBytes',
      );
      // Determine the proper reference based on media type
      Reference baseRef;
      switch (mediaType) {
        case 'image':
          baseRef = _imagesRef;
          break;
        case 'audio':
          baseRef = _audioRef;
          break;
        case 'video':
          baseRef = _videoRef;
          break;
        default:
          _logger.logError(
            'Invalid media type: $mediaType',
            'Invalid media type provided',
            null,
            'StorageService.uploadBytes',
          );
          throw Exception('Invalid media type: $mediaType');
      }

      // Generate a unique filename with the provided extension
      final String fileName =
          '${questionId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      final Reference ref = baseRef.child(fileName);

      // Upload the bytes
      _logger.logDebug(
        'Uploading ${bytes.length} bytes of $mediaType data',
        'StorageService.uploadBytes',
      );
      final UploadTask uploadTask = ref.putData(bytes);

      // Wait for the upload to complete
      await uploadTask;

      // Get and return the download URL
      final downloadUrl = await ref.getDownloadURL();
      _logger.logInfo(
        'Media bytes uploaded successfully as $mediaType: $fileName',
        'StorageService.uploadBytes',
      );
      return downloadUrl;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error uploading bytes',
        e,
        stackTrace,
        'StorageService.uploadBytes',
      );
      debugPrint('Error uploading bytes: $e');
      rethrow;
    }
  }

  // Delete a media file from storage using the download URL
  Future<void> deleteMedia(String downloadUrl) async {
    try {
      _logger.logInfo(
        'Attempting to delete media: $downloadUrl',
        'StorageService.deleteMedia',
      );
      // Create a reference from the download URL
      final Reference ref = FirebaseStorage.instance.refFromURL(downloadUrl);
      await ref.delete();
      _logger.logInfo(
        'Media file deleted successfully: ${ref.name}',
        'StorageService.deleteMedia',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting media',
        e,
        stackTrace,
        'StorageService.deleteMedia',
      );
      debugPrint('Error deleting media: $e');
      rethrow;
    }
  }

  // Clear all media associated with a quiz session
  Future<void> clearSessionMedia(String sessionId) async {
    try {
      _logger.logInfo(
        'Clearing all media for session: $sessionId',
        'StorageService.clearSessionMedia',
      );
      // List all files in each media directory
      final ListResult imagesResult = await _imagesRef.list();
      final ListResult audioResult = await _audioRef.list();
      final ListResult videoResult = await _videoRef.list();

      _logger.logDebug(
        'Found ${imagesResult.items.length} images, ${audioResult.items.length} audio files, ${videoResult.items.length} videos to check',
        'StorageService.clearSessionMedia',
      );

      // Combine all references
      final List<Reference> allRefs = [
        ...imagesResult.items,
        ...audioResult.items,
        ...videoResult.items,
      ];

      int deletedCount = 0;
      // Filter and delete files associated with the session
      for (Reference ref in allRefs) {
        if (ref.name.contains(sessionId)) {
          await ref.delete();
          deletedCount++;
          _logger.logDebug(
            'Deleted ${ref.name}',
            'StorageService.clearSessionMedia',
          );
        }
      }
      _logger.logInfo(
        'Cleared $deletedCount media files for session: $sessionId',
        'StorageService.clearSessionMedia',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error clearing session media for session: $sessionId',
        e,
        stackTrace,
        'StorageService.clearSessionMedia',
      );
      debugPrint('Error clearing session media: $e');
      rethrow;
    }
  }

  // Compress an image file to reduce upload size and bandwidth
  Future<File?> _compressImage(File file) async {
    try {
      _logger.logDebug(
        'Compressing image file: ${file.path}',
        'StorageService._compressImage',
      );
      final filePath = file.path;
      final lastIndex = filePath.lastIndexOf('.');
      final outPath = '${filePath.substring(0, lastIndex)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 70,
      );

      if (result != null) {
        _logger.logDebug(
          'Image compressed successfully. Original size: ${file.lengthSync()}, compressed size: ${File(result.path).lengthSync()}',
          'StorageService._compressImage',
        );
      } else {
        _logger.logWarning(
          'Image compression returned null result',
          'StorageService._compressImage',
        );
      }

      return result != null ? File(result.path) : null;
    } catch (e, stackTrace) {
      _logger.logError(
        'Error compressing image',
        e,
        stackTrace,
        'StorageService._compressImage',
      );
      debugPrint('Error compressing image: $e');
      return null;
    }
  }

  // Get list of all media files (for admin purposes)
  Future<Map<String, List<String>>> getAllMedia() async {
    try {
      _logger.logInfo(
        'Retrieving all media files',
        'StorageService.getAllMedia',
      );
      final ListResult imagesResult = await _imagesRef.list();
      final ListResult audioResult = await _audioRef.list();
      final ListResult videoResult = await _videoRef.list();

      _logger.logDebug(
        'Found ${imagesResult.items.length} images, ${audioResult.items.length} audio files, ${videoResult.items.length} videos',
        'StorageService.getAllMedia',
      );

      final List<String> imageUrls = [];
      final List<String> audioUrls = [];
      final List<String> videoUrls = [];

      // Get image URLs
      for (Reference ref in imagesResult.items) {
        try {
          final url = await ref.getDownloadURL();
          imageUrls.add(url);
        } catch (e) {
          _logger.logWarning(
            'Could not get URL for image: ${ref.name}: $e',
            'StorageService.getAllMedia',
          );
        }
      }

      // Get audio URLs
      for (Reference ref in audioResult.items) {
        try {
          final url = await ref.getDownloadURL();
          audioUrls.add(url);
        } catch (e) {
          _logger.logWarning(
            'Could not get URL for audio: ${ref.name}: $e',
            'StorageService.getAllMedia',
          );
        }
      }

      // Get video URLs
      for (Reference ref in videoResult.items) {
        try {
          final url = await ref.getDownloadURL();
          videoUrls.add(url);
        } catch (e) {
          _logger.logWarning(
            'Could not get URL for video: ${ref.name}: $e',
            'StorageService.getAllMedia',
          );
        }
      }

      _logger.logInfo(
        'Retrieved ${imageUrls.length} image URLs, ${audioUrls.length} audio URLs, ${videoUrls.length} video URLs',
        'StorageService.getAllMedia',
      );

      return {'images': imageUrls, 'audio': audioUrls, 'video': videoUrls};
    } catch (e, stackTrace) {
      _logger.logError(
        'Error getting all media',
        e,
        stackTrace,
        'StorageService.getAllMedia',
      );
      debugPrint('Error getting all media: $e');
      return {'images': [], 'audio': [], 'video': []};
    }
  }
}
