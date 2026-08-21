import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../domain/use_cases/update_profile_use_case.dart';

class EditProfilePage extends StatefulWidget {
  final RegisteredUserEntity user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _name;
  late final TextEditingController _bio;
  File? _pickedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _bio = TextEditingController(text: widget.user.bio ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await di.sl<UpdateProfileUseCase>()(
      UpdateProfileParams(
        uid: widget.user.userId,
        name: name,
        bio: _bio.text.trim(),
        imagePath: _pickedImage?.path,
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(
                children: [
                  if (_pickedImage != null)
                    CircleAvatar(
                      radius: 56,
                      backgroundImage: FileImage(_pickedImage!),
                    )
                  else
                    UserAvatar(
                      name: widget.user.name,
                      photoUrl: widget.user.profilePic,
                      radius: 56,
                    ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.seed,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickImage,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Your name'),
            ),
            const SizedBox(height: 20),
            const Text('Bio', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _bio,
              maxLength: 140,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'A little about you',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
