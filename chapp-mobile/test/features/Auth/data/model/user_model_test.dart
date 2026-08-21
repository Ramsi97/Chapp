import 'package:chapp/features/Auth/data/model/user_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';

void main() {
  group('UserModel', () {
    final entity = UserEntity(
      userId: 'u123',
      phoneNumber: '+1234567890',
    );

    final json = {
      'userId': 'u123',
      'phoneNumber': '+1234567890',
    };

    test('fromJson should parse correctly', () {
      final model = UserModel.fromJson(json);

      expect(model.userId, entity.userId);
      expect(model.phoneNumber, entity.phoneNumber);
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
    });

    test('equality check', () {
      final model1 = UserModel.fromEntity(entity);
      final model2 = UserModel.fromEntity(entity);

      expect(model1.userId, model2.userId);
      expect(model1, equals(model2));
    });
  });
}
