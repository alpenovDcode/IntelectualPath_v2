import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class ImageHelper {
  static final ImagePicker _picker = ImagePicker();
  
  /// Выбирает изображение из галереи с оптимизацией
  static Future<String?> pickImageFromGallery({
    int maxWidth = 512,
    int maxHeight = 512,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Ошибка при выборе изображения из галереи: $e');
      return null;
    }
  }
  
  /// Выбирает изображение с камеры с оптимизацией
  static Future<String?> pickImageFromCamera({
    int maxWidth = 512,
    int maxHeight = 512,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        return image.path;
      }
      return null;
    } catch (e) {
      print('Ошибка при съемке с камеры: $e');
      return null;
    }
  }
  
  /// Сохраняет изображение в постоянную директорию приложения
  static Future<String?> saveImageToAppDirectory(String imagePath, String userId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localPath = '${directory.path}/$fileName';
      
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        print('Исходный файл не существует: $imagePath');
        return null;
      }
      
      final localFile = await imageFile.copy(localPath);
      return localFile.path;
    } catch (e) {
      print('Ошибка при сохранении изображения: $e');
      return null;
    }
  }
  
  /// Проверяет существование файла изображения
  static bool imageExists(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return false;
    
    if (imagePath.startsWith('http')) {
      return true; // Для сетевых изображений не можем проверить, поэтому предполагаем true
    }
    
    final file = File(imagePath);
    return file.existsSync();
  }
  
  /// Создает безопасный виджет изображения профиля
  static Widget buildProfileImage({
    required String? imagePath,
    required String userName,
    required double size,
    required Color backgroundColor,
    bool isCircular = true,
    BorderRadius? borderRadius,
  }) {
    Widget child;
    
    if (imagePath == null || imagePath.isEmpty || !imageExists(imagePath)) {
      // Аватар по умолчанию
      child = Container(
        width: size,
        height: size,
        color: backgroundColor,
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: TextStyle(
              fontSize: size * 0.4,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else if (imagePath.startsWith('http')) {
      // Сетевое изображение
      child = Image.network(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Ошибка загрузки сетевого изображения: $error');
          return Container(
            width: size,
            height: size,
            color: backgroundColor,
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            color: backgroundColor,
            child: Center(
              child: SizedBox(
                width: size * 0.3,
                height: size * 0.3,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        },
      );
    } else {
      // Локальное изображение
      child = Image.file(
        File(imagePath),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Ошибка загрузки локального изображения: $error');
          return Container(
            width: size,
            height: size,
            color: backgroundColor,
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      );
    }
    
    if (isCircular) {
      return ClipOval(child: child);
    } else if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius, child: child);
    }
    
    return child;
  }
  
  /// Удаляет старое изображение профиля
  static Future<void> deleteOldProfileImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty || imagePath.startsWith('http')) {
      return;
    }
    
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
        print('Старое изображение удалено: $imagePath');
      }
    } catch (e) {
      print('Ошибка при удалении старого изображения: $e');
    }
  }
  
  /// Показывает диалог выбора источника изображения
  static Future<String?> showImageSourceDialog(BuildContext context, String userId) async {
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Выберите источник'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Из галереи'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagePath = await pickImageFromGallery();
                  if (imagePath != null) {
                    final savedPath = await saveImageToAppDirectory(imagePath, userId);
                    Navigator.of(context).pop(savedPath);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Сделать фото'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final imagePath = await pickImageFromCamera();
                  if (imagePath != null) {
                    final savedPath = await saveImageToAppDirectory(imagePath, userId);
                    Navigator.of(context).pop(savedPath);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
          ],
        );
      },
    );
  }
} 