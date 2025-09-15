import 'package:chapp/features/Auth/data/model/new_user_model.dart';
import 'package:chapp/features/Auth/domain/entity/new_user_entity.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('NewUserModel', () {
    final json = {
      'userId': '123',
      'phoneNumber': '+1234567890',
      'fullName': 'John Doe',
      'profilePic': 'profile.png',
      'bio': 'Hello world!',
      'isOnline': true,
      'createdAt': '2025-09-15T12:00:00.000Z',
    };

    final entity = NewUserEntity(
      userId: '123',
      phoneNumber: '+1234567890',
      fullName: 'John Doe',
      profilePic: 'profile.png',
      bio: 'Hello world!',
      isOnline: true,
      createdAt: DateTime.parse('2025-09-15T12:00:00.000Z'),
    );

    test('fromJson should return a valid model', () {
      final model = NewUserModel.fromJson(json);

      expect(model.userId, entity.userId);
      expect(model.phoneNumber, entity.phoneNumber);
      expect(model.fullName, entity.fullName);
      expect(model.profilePic, entity.profilePic);
      expect(model.bio, entity.bio);
      expect(model.isOnline, entity.isOnline);
      expect(model.createdAt, entity.createdAt);
    });

    test('toJson should return a valid map', () {
      final model = NewUserModel.fromEntity(entity);
      final modelJson = model.toJson();

      expect(modelJson['userId'], json['userId']);
      expect(modelJson['phoneNumber'], json['phoneNumber']);
      expect(modelJson['fullName'], json['fullName']);
      expect(modelJson['profilePic'], json['profilePic']);
      expect(modelJson['bio'], json['bio']);
      expect(modelJson['isOnline'], json['isOnline']);
      expect(modelJson['createdAt'], json['createdAt']);
    });

    test('fromEntity should return a valid model', () {
      final model = NewUserModel.fromEntity(entity);

      expect(model, isA<NewUserModel>());
      expect(model.userId, entity.userId);
      expect(model.phoneNumber, entity.phoneNumber);
      expect(model.fullName, entity.fullName);
    });

    test('equatable props should work', () {
      final model1 = NewUserModel.fromEntity(entity);
      final model2 = NewUserModel.fromEntity(entity);

      expect(model1, model2); // Equatable makes them equal
    });
  });
}
