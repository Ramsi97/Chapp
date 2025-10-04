import 'package:bloc/bloc.dart';
import 'package:chapp/core/use_case/use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/check_authenticated_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/log_out_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/login_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/register_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/resend_otp_use_case.dart';
import 'package:chapp/features/Auth/domain/use_cases/verify_otp_manual_use_case.dart';
import 'package:meta/meta.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogOutUseCase logOutUseCase;
  final RegisterUseCase registerUseCase;
  final VerifyOtpManualUseCase verifyOtpManualUseCase;
  final ResendOtpUseCase resendOtpUseCase;
  final CheckAuthenticatedUseCase checkAuthenticatedUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logOutUseCase,
    required this.registerUseCase,
    required this.verifyOtpManualUseCase,
    required this.resendOtpUseCase,
    required this.checkAuthenticatedUseCase,
  }) : super(AuthInitial()) {
    on<AuthRequestOtp>((event, emit) async {
      emit(AuthLoading());
      final result = await loginUseCase(
        LoginUseCaseParams(phoneNumber: event.phoneNumber),
      );
      result.fold((failure) => emit(AuthFailure(failure.message)), (success) {
        if (success.userEntity != null) {
          emit(Authenticated());
        } else {
          emit(
            OtpSent(
              success.otpVerificationData?.verificationId ?? "",
              success.otpVerificationData?.resendToken,
            ),
          );
        }
      });
    });

    on<AuthVerifyOtp>((event, emit) async {
      final result = await verifyOtpManualUseCase(
        VerifyOtpManualUseCaseParams(
          verificationId: event.verificationId,
          smsCode: event.otp,
        ),
      );

      result.fold((failure) => emit(AuthFailure(failure.message)), (success) {
        emit(Authenticated());
      });
    });

    on<AuthResendOtp>((event, emit) async {
      final result = await resendOtpUseCase(
        ResendOtpUseCaseParams(
          phoneNumber: event.phoneNumber,
          forceResendingToken: event.forceResendingToken,
        ),
      );

      result.fold((failure) => emit(AuthFailure(failure.message)), (success) {
        if (success.userEntity != null) {
          emit(Authenticated());
        } else {
          emit(
            OtpSent(
              success.otpVerificationData?.verificationId ?? "",
              success.otpVerificationData?.resendToken,
            ),
          );
        }
      });
    });

    on<AuthCheckStatus>((event, emit) async {
      final result = await checkAuthenticatedUseCase(NoParams());
      result.fold((failure) => emit(AuthFailure(failure.message)), (success) {
        if (success) {
          emit(Authenticated());
        } else {
          emit(Unauthenticated());
        }
      });
    });
  }
}
