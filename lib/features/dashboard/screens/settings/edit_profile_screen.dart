import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/theme.dart';
import '../../../../widgets/buttons.dart';
import '../../../../utils/image_helper.dart';
import '../../../auth/bloc/auth_bloc.dart';
import '../../../auth/models/user.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;
  
  const EditProfileScreen({
    super.key,
    required this.user,
  });

  @override
  EditProfileScreenState createState() => EditProfileScreenState();
}

class EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _phoneController;
  String _profileImagePath = '';
  String _oldImagePath = '';
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUserData();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
  
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final bio = prefs.getString('user_bio_${widget.user.id}') ?? '';
    final phone = prefs.getString('user_phone_${widget.user.id}') ?? '';
    final imagePath = prefs.getString('user_avatar_${widget.user.id}') ?? '';
    
    setState(() {
      _bioController.text = bio;
      _phoneController.text = phone;
      _profileImagePath = imagePath;
      _oldImagePath = imagePath;
    });
  }
  
  Future<void> _pickImage() async {
    try {
      final newImagePath = await ImageHelper.showImageSourceDialog(context, widget.user.id);
      
      if (newImagePath != null) {
        setState(() {
          _profileImagePath = newImagePath;
        });
      }
    } catch (e) {
      print('Ошибка при выборе изображения: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выборе изображения: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Сохраняем данные профиля
      await prefs.setString('user_name_${widget.user.id}', _nameController.text);
      await prefs.setString('user_bio_${widget.user.id}', _bioController.text);
      await prefs.setString('user_phone_${widget.user.id}', _phoneController.text);
      
      if (_profileImagePath.isNotEmpty) {
        await prefs.setString('user_avatar_${widget.user.id}', _profileImagePath);
        
        // Удаляем старое изображение, если оно отличается от нового
        if (_oldImagePath != _profileImagePath && _oldImagePath.isNotEmpty) {
          await ImageHelper.deleteOldProfileImage(_oldImagePath);
        }
      }
      
      // Обновляем пользователя в блоке
      final updatedUser = User(
        id: widget.user.id,
        name: _nameController.text,
        email: widget.user.email,
        photoUrl: _profileImagePath,
      );
      
      context.read<AuthBloc>().add(AuthUpdateUserEvent(user: updatedUser));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль успешно обновлен'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context, true);
    } catch (e) {
      print('Ошибка при сохранении профиля: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Фото профиля
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ImageHelper.buildProfileImage(
                              imagePath: _profileImagePath,
                              userName: widget.user.name,
                              size: 120,
                              backgroundColor: AppTheme.primaryColor,
                              isCircular: true,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Имя
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Имя',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Пожалуйста, введите имя';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Email (только для чтения)
                    TextFormField(
                      initialValue: widget.user.email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Телефон
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Телефон',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Биография
                    TextFormField(
                      controller: _bioController,
                      decoration: const InputDecoration(
                        labelText: 'О себе',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Кнопка сохранения
                    SizedBox(
                      width: double.infinity,
                      child: AppButton(
                        text: 'Сохранить изменения',
                        onPressed: _saveProfile,
                        type: AppButtonType.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 