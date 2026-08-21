import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/widgets/user_avatar.dart';
import '../../../../injection.dart' as di;
import '../../../Auth/domain/entity/registered_user_entity.dart';
import '../../../Users/domain/use_cases/get_users_use_case.dart';
import '../../domain/use_cases/create_group_chat_use_case.dart';
import 'chat_page.dart';

class NewGroupPage extends StatefulWidget {
  const NewGroupPage({super.key});

  @override
  State<NewGroupPage> createState() => _NewGroupPageState();
}

class _NewGroupPageState extends State<NewGroupPage> {
  final TextEditingController _name = TextEditingController();
  final Set<String> _selected = {};

  List<RegisteredUserEntity> _users = [];
  File? _photo;
  bool _loading = true;
  bool _creating = false;
  String? _error;

  String? get _myUid => di.sl<FirebaseAuth>().currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final myUid = _myUid;
    if (myUid == null) {
      setState(() {
        _loading = false;
        _error = 'Not signed in';
      });
      return;
    }
    final result = await di.sl<GetUsersUseCase>()(
      GetUsersParams(excludeUid: myUid),
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _loading = false;
        _error = failure.message;
      }),
      (users) => setState(() {
        _loading = false;
        _users = users;
      }),
    );
  }

  Future<void> _pickPhoto() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
      maxWidth: 1024,
    );
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _create() async {
    final myUid = _myUid;
    if (myUid == null) return;
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a group name')),
      );
      return;
    }
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one member')),
      );
      return;
    }

    setState(() => _creating = true);
    final result = await di.sl<CreateGroupChatUseCase>()(
      CreateGroupChatParams(
        name: name,
        createdBy: myUid,
        participants: [myUid, ..._selected],
        imagePath: _photo?.path,
      ),
    );
    if (!mounted) return;
    setState(() => _creating = false);

    result.fold(
      (failure) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message)),
      ),
      (chat) => Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ChatPage(chat: chat, myUid: myUid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New group'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _create,
            child: _creating
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: _photo != null
                            ? CircleAvatar(
                                radius: 28,
                                backgroundImage: FileImage(_photo!),
                              )
                            : const UserAvatar(
                                name: '',
                                radius: 28,
                                fallbackIcon: Icons.camera_alt,
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Group name',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selected.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${_selected.length} selected',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const Divider(height: 16),
                Expanded(
                  child: _users.isEmpty
                      ? const Center(child: Text('No other users yet'))
                      : ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final selected = _selected.contains(user.userId);
                            return CheckboxListTile(
                              value: selected,
                              controlAffinity:
                                  ListTileControlAffinity.trailing,
                              secondary: UserAvatar(
                                name: user.name,
                                photoUrl: user.profilePic,
                                radius: 22,
                              ),
                              title: Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text('@${user.username}'),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selected.add(user.userId);
                                  } else {
                                    _selected.remove(user.userId);
                                  }
                                });
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
