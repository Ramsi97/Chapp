import 'package:chapp/features/Auth/data/model/registered_user_model.dart';
import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final model = RegisteredUserModel(
    userId: 'user1',
    name: 'Test User',
    username: 'TestUser',
    phoneNumber: '+251900000000',
    profilePic: 'https://example.com/a.jpg',
    bio: 'hello there',
    isOnline: true,
    lastActiveAt: DateTime(2025, 1, 2, 3, 4, 5),
    contacts: const ['a', 'b'],
    blockedUsers: const ['c'],
    settings: const {'theme': 'dark'},
    createdAt: DateTime(2024, 12, 25, 10, 30),
  );

  group('RegisteredUserModel', () {
    test('is a RegisteredUserEntity', () {
      expect(model, isA<RegisteredUserEntity>());
    });

    test('toJson stores Timestamps and a lowercased username', () {
      final json = model.toJson();

      expect(json['userId'], 'user1');
      expect(json['username'], 'TestUser');
      // usernameLower is derived for prefix search.
      expect(json['usernameLower'], 'testuser');
      expect(json['lastActiveAt'], isA<Timestamp>());
      expect(json['createdAt'], isA<Timestamp>());
      expect(
        (json['lastActiveAt'] as Timestamp).toDate(),
        DateTime(2025, 1, 2, 3, 4, 5),
      );
    });

    test('fromJson(toJson(x)) round-trips to an equal entity', () {
      final restored = RegisteredUserModel.fromJson(model.toJson());
      expect(restored, model);
    });

    test('fromEntity copies every field', () {
      final entity = RegisteredUserEntity(
        userId: 'u2',
        name: 'Another',
        username: 'another',
        phoneNumber: '+251911111111',
        profilePic: null,
        bio: null,
        isOnline: false,
        lastActiveAt: DateTime(2023, 5, 5),
        contacts: const [],
        blockedUsers: const [],
        settings: const {},
        createdAt: DateTime(2023, 5, 5),
      );

      expect(RegisteredUserModel.fromEntity(entity), entity);
    });

    test('fromJson tolerates missing/null fields with safe defaults', () {
      final restored = RegisteredUserModel.fromJson(const {});

      expect(restored.userId, '');
      expect(restored.name, '');
      expect(restored.username, '');
      expect(restored.phoneNumber, '');
      expect(restored.profilePic, isNull);
      expect(restored.bio, isNull);
      expect(restored.isOnline, false);
      expect(restored.contacts, isEmpty);
      expect(restored.blockedUsers, isEmpty);
      expect(restored.settings, isEmpty);
    });

    test('fromJson reads a DateTime lastActiveAt without a Timestamp', () {
      final json = model.toJson();
      json['lastActiveAt'] = DateTime(2022, 2, 2);

      final restored = RegisteredUserModel.fromJson(json);
      expect(restored.lastActiveAt, DateTime(2022, 2, 2));
    });
  });
}
