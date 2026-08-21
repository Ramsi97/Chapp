import 'package:chapp/features/Auth/data/datasources/auth_local_data_source.dart';
import 'package:chapp/features/Auth/data/datasources/auth_remote_data_source.dart';
import 'package:chapp/features/Auth/data/repository/auth_repository_impl.dart';
import 'package:chapp/features/Auth/domain/repository/auth_repository.dart';
import 'package:chapp/features/Auth/domain/use_cases/check_profile_exists_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/log_out_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/login_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/register_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/verify_otp_manual_use_case.dart';
import 'package:chapp/features/Auth/presentation/bloc/auth_bloc.dart';
import 'package:chapp/features/Chat/data/datasources/chat_remote_data_source.dart';
import 'package:chapp/features/Chat/data/repository/chat_repository_impl.dart';
import 'package:chapp/features/Chat/domain/repository/chat_repository.dart';
import 'package:chapp/features/Chat/domain/use_cases/create_group_chat_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/get_or_create_direct_chat_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/mark_chat_read_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/send_message_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/set_typing_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/watch_chat_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/watch_chats_use_case.dart';
import 'package:chapp/features/Chat/domain/use_cases/watch_messages_use_case.dart';
import 'package:chapp/features/Chat/presentation/bloc/chat_list_bloc.dart';
import 'package:chapp/features/Chat/presentation/bloc/messaging_bloc.dart';
import 'package:chapp/features/Users/data/datasources/users_remote_data_source.dart';
import 'package:chapp/features/Users/data/repository/users_repository_impl.dart';
import 'package:chapp/features/Users/domain/repository/users_repository.dart';
import 'package:chapp/features/Users/domain/use_cases/get_user_use_case.dart';
import 'package:chapp/features/Users/domain/use_cases/get_users_use_case.dart';
import 'package:chapp/features/Users/domain/use_cases/update_presence_use_case.dart';
import 'package:chapp/features/Users/domain/use_cases/update_profile_use_case.dart';
import 'package:chapp/features/Users/domain/use_cases/watch_user_use_case.dart';
import 'package:chapp/features/Users/presentation/bloc/users_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

import 'core/network/network_info.dart';

final sl = GetIt.instance;

Future<void> init() async {
  _initExternal();
  _initCore();
  _initAuth();
  _initUsers();
  _initChat();
}

void _initExternal() {
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => FirebaseFirestore.instance);
  sl.registerLazySingleton(() => FirebaseStorage.instance);
  sl.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.createInstance(),
  );
}

void _initCore() {
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
}

void _initAuth() {
  // Bloc
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logOutUseCase: sl(),
      registerUseCase: sl(),
      verifyOtpManualUseCase: sl(),
      resendOtpUseCase: sl(),
      getCurrentUserUseCase: sl(),
      checkProfileExistsUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUseCase(repository: sl()));
  sl.registerLazySingleton(() => RegisterUseCase(repository: sl()));
  sl.registerLazySingleton(() => VerifyOtpManualUseCase(repository: sl()));
  sl.registerLazySingleton(() => ResendOtpUseCase(repository: sl()));
  sl.registerLazySingleton(() => LogOutUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(repository: sl()));
  sl.registerLazySingleton(() => CheckProfileExistsUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      firestore: sl(),
      storage: sl(),
    ),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(firebaseAuth: sl()),
  );
}

void _initUsers() {
  // Bloc
  sl.registerFactory(() => UsersBloc(getUsersUseCase: sl()));

  // Use cases
  sl.registerLazySingleton(() => GetUsersUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetUserUseCase(repository: sl()));
  sl.registerLazySingleton(() => WatchUserUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdatePresenceUseCase(repository: sl()));
  sl.registerLazySingleton(() => UpdateProfileUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<UsersRepository>(
    () => UsersRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data source
  sl.registerLazySingleton<UsersRemoteDataSource>(
    () => UsersRemoteDataSourceImpl(firestore: sl(), storage: sl()),
  );
}

void _initChat() {
  // Blocs
  sl.registerFactory(() => ChatListBloc(watchChatsUseCase: sl()));
  sl.registerFactory(
    () => MessagingBloc(
      watchMessagesUseCase: sl(),
      watchChatUseCase: sl(),
      sendMessageUseCase: sl(),
      setTypingUseCase: sl(),
      markChatReadUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => WatchChatsUseCase(repository: sl()));
  sl.registerLazySingleton(() => WatchChatUseCase(repository: sl()));
  sl.registerLazySingleton(() => WatchMessagesUseCase(repository: sl()));
  sl.registerLazySingleton(() => SendMessageUseCase(repository: sl()));
  sl.registerLazySingleton(() => GetOrCreateDirectChatUseCase(repository: sl()));
  sl.registerLazySingleton(() => CreateGroupChatUseCase(repository: sl()));
  sl.registerLazySingleton(() => MarkChatReadUseCase(repository: sl()));
  sl.registerLazySingleton(() => SetTypingUseCase(repository: sl()));

  // Repository
  sl.registerLazySingleton<ChatRepository>(
    () => ChatRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
  );

  // Data source
  sl.registerLazySingleton<ChatRemoteDataSource>(
    () => ChatRemoteDataSourceImpl(firestore: sl(), storage: sl()),
  );
}
