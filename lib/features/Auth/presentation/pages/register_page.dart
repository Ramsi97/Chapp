import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../bloc/auth_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  File? _profileImage;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _onSignUp() {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final bio = _bioController.text.trim();

    if (name.isEmpty) {
      _snack("Please enter your name");
      return;
    }
    if (username.isEmpty) {
      _snack("Please choose a username");
      return;
    }

    context.read<AuthBloc>().add(
      AuthRegister(
        name: name,
        username: username,
        bio: bio.isEmpty ? null : bio,
        imagePath: _profileImage?.path,
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) _snack(state.message);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Set Up Your Profile"),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: "Cancel",
            onPressed: () => context.read<AuthBloc>().add(AuthLogout()),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF5B6EF5), Color(0xFF9B5BF5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: _profileImage == null
                          ? const Icon(
                              Icons.person,
                              size: 54,
                              color: Colors.white,
                            )
                          : ClipOval(
                              child: Image.file(
                                _profileImage!,
                                width: 108,
                                height: 108,
                                fit: BoxFit.cover,
                              ),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 4,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.scaffoldBackgroundColor,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  "Tell us a little about yourself.",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: "Name",
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    hintText: "Username",
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bioController,
                  maxLines: 2,
                  maxLength: 140,
                  decoration: const InputDecoration(
                    hintText: "Bio (optional)",
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                ),
                const Spacer(),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final isLoading = state is AuthLoading;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _onSignUp,
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text("Sign Up"),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  "By signing up, you agree to our Terms of Service and Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
