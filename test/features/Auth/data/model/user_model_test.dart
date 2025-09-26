import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';

void main() {
  group('UserModel', () {
    final entity = UserEntity(
      userId: 'u123',
      name: 'John Doe',
      username: 'johndoe',
      phoneNumber: '+1234567890',
      profilePic: 'profile.png',
      bio: 'Hello world!',
      isOnline: true,
      lastActiveAt: DateTime.parse('2025-09-15T12:00:00.000Z'),
      contacts: ['u456', 'u789'],
      blockedUsers: ['u999'],
      settings: {'theme': 'dark'},
      createdAt: DateTime.parse('2025-01-01T10:00:00.000Z'),
    );

    final json = {
      'userId': 'u123',
      'name': 'John Doe',
      'username': 'johndoe',
      'phoneNumber': '+1234567890',
      'profilePic': 'profile.png',
      'bio': 'Hello world!',
      'isOnline': true,
      'lastActiveAt': '2025-09-15T12:00:00.000Z',
      'contacts': ['u456', 'u789'],
      'blockedUsers': ['u999'],
      'settings': {'theme': 'dark'},
      'createdAt': '2025-01-01T10:00:00.000Z',
    };

    test('fromJson should parse correctly', () {
      final model = UserModel.fromJson(json);

      expect(model.userId, entity.userId);
      expect(model.name, entity.name);
      expect(model.username, entity.username);
      expect(model.phoneNumber, entity.phoneNumber);
      expect(model.profilePic, entity.profilePic);
      expect(model.bio, entity.bio);
      expect(model.isOnline, entity.isOnline);
      expect(model.lastActiveAt, entity.lastActiveAt);
      expect(model.contacts, entity.contacts);
      expect(model.blockedUsers, entity.blockedUsers);
      expect(model.settings, entity.settings);
      expect(model.createdAt, entity.createdAt);
    });

    test('toJson should convert correctly', () {
      final model = UserModel.fromEntity(entity);
      final modelJson = model.toJson();

      expect(modelJson, json);
    });

    test('fromEntity should convert correctly', () {
      final model = UserModel.fromEntity(entity);

      expect(model, isA<UserModel>());
      expect(model.userId, entity.userId);
      expect(model.name, entity.name);
      expect(model.username, entity.username);
    });

    test('equality check', () {
      final model1 = UserModel.fromEntity(entity);
      final model2 = UserModel.fromEntity(entity);

      expect(model1.userId, model2.userId);
      expect(model1, equals(model2));
    });
  });
}
