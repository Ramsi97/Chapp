import 'package:bloc/bloc.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/entity/registered_user_entity.dart';
import 'package:chapp/features/Auth/domain/entity/user_entity.dart';
import 'package:chapp/features/Auth/domain/use_cases/check_profile_exists_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/get_current_user_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/log_out_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/login_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/register_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/verify_otp_manual_use_case.dart';
import 'package:flutter/foundation.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogOutUseCase logOutUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyOtpManualUseCase verifyOtpManualUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final CheckProfileExistsUseCase checkProfileExistsUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logOutUseCase,
    required this.registerUseCase,
    required this.verifyOtpManualUseCase,
    required this.resendOtpUseCase,
    required this.getCurrentUserUseCase,
    required this.checkProfileExistsUseCase,
  }) : super(AuthInitial()) {
    on<AuthRequestOtp>(_onRequestOtp);
    on<AuthVerifyOtp>(_onVerifyOtp);
    on<AuthResendOtp>(_onResendOtp);
    on<AuthCheckStatus>(_onCheckStatus);
    on<AuthRegister>(_onRegister);
    on<AuthLogout>(_onLogout);
    on<AuthClearError>((event, emit) => emit(AuthNoError()));
  }

  Future<void> _onRequestOtp(
    AuthRequestOtp event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await loginUseCase(
      LoginUseCaseParams(phoneNumber: event.phoneNumber),
    );
    await result.fold(
      (failure) async => _fail(failure.message, emit),
      (success) async {
        if (success.userEntity != null) {
          await _routeAfterAuth(success.userEntity!, emit);
        } else {
          emit(
            OtpSent(
              success.otpVerificationData?.verificationId ?? "",
              success.otpVerificationData?.resendToken,
            ),
          );
        }
      },
    );
  }

  Future<void> _onVerifyOtp(AuthVerifyOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await verifyOtpManualUseCase(
      VerifyOtpManualUseCaseParams(
        verificationId: event.verificationId,
        smsCode: event.otp,
      ),
    );
    await result.fold(
      (failure) async => _fail(failure.message, emit),
      (user) async => _routeAfterAuth(user, emit),
    );
  }

  Future<void> _onResendOtp(AuthResendOtp event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await resendOtpUseCase(
      ResendOtpUseCaseParams(
        phoneNumber: event.phoneNumber,
        forceResendingToken: event.forceResendingToken,
      ),
    );
    await result.fold(
      (failure) async => _fail(failure.message, emit),
      (success) async {
        if (success.userEntity != null) {
          await _routeAfterAuth(success.userEntity!, emit);
        } else {
          emit(
            OtpSent(
              success.otpVerificationData?.verificationId ?? "",
              success.otpVerificationData?.resendToken,
            ),
          );
        }
      },
    );
  }

  Future<void> _onCheckStatus(
    AuthCheckStatus event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUserUseCase(NoParams());
    await result.fold(
      (failure) async => emit(Unauthenticated()),
      (user) async {
        if (user == null) {
          emit(Unauthenticated());
        } else {
          // On startup, don't lock the user out if profile check fails offline.
          await _routeAfterAuth(user, emit, optimisticOnError: true);
        }
      },
    );
  }

  Future<void> _onRegister(AuthRegister event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final currentUserResult = await getCurrentUserUseCase(NoParams());
    await currentUserResult.fold(
      (failure) async => _fail(failure.message, emit),
      (user) async {
        if (user == null) {
          emit(Unauthenticated());
          return;
        }
        final now = DateTime.now();
        final profile = RegisteredUserEntity(
          userId: user.userId,
          name: event.name,
          username: event.username,
          phoneNumber: user.phoneNumber,
          profilePic: null,
          bio: event.bio,
          isOnline: true,
          lastActiveAt: now,
          contacts: const [],
          blockedUsers: const [],
          settings: const {},
          createdAt: now,
        );
        final result = await registerUseCase(
          RegisterParams(user: profile, imagePath: event.imagePath),
        );
        result.fold(
          (failure) => _fail(failure.message, emit),
          (_) => emit(Authenticated()),
        );
      },
    );
  }

  Future<void> _onLogout(AuthLogout event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await logOutUseCase(NoParams());
    result.fold(
      (failure) => _fail(failure.message, emit),
      (_) => emit(Unauthenticated()),
    );
  }

  /// Decides where a freshly-authenticated user should land: straight into the
  /// app if their profile exists, otherwise into profile setup.
  Future<void> _routeAfterAuth(
    UserEntity user,
    Emitter<AuthState> emit, {
    bool optimisticOnError = false,
  }) async {
    final result = await checkProfileExistsUseCase(
      CheckProfileExistsParams(userId: user.userId),
    );
    result.fold(
      (failure) {
        if (optimisticOnError) {
          emit(Authenticated());
        } else {
          _fail(failure.message, emit);
        }
      },
      (exists) => emit(
        exists
            ? Authenticated()
            : ProfileSetupRequired(
                userId: user.userId,
                phoneNumber: user.phoneNumber,
              ),
      ),
    );
  }

  void _fail(String message, Emitter<AuthState> emit) {
    emit(AuthFailure(message));
    Future.delayed(const Duration(seconds: 5), () {
      if (!isClosed) add(AuthClearError());
    });
  }
}
