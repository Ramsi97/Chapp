import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';

class OtpPage extends StatefulWidget {
  final String verificationId;
  final int? forceResendingToken;
  final String phoneNumber;

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.forceResendingToken,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final int _otpLength = 6;
  List<FocusNode> _focusNodes = [];
  List<TextEditingController> _controllers = [];

  late String _verificationId;
  int? _resendToken;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _verificationId = widget.verificationId;
    _resendToken = widget.forceResendingToken;
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (_hasError) {
      setState(() => _hasError = false);
    }
    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    setState(() {});

    if (_otp.length == _otpLength && !_otp.contains(" ")) {
      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(AuthVerifyOtp(_verificationId, _otp));
    }
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _resend() {
    context.read<AuthBloc>().add(
      AuthResendOtp(widget.phoneNumber, _resendToken),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated || state is ProfileSetupRequired) {
          // Reveal the AuthGate, which has already rebuilt to the right screen.
          Navigator.of(context).popUntil((route) => route.isFirst);
        } else if (state is AuthFailure) {
          setState(() => _hasError = true);
        } else if (state is OtpSent) {
          // A resend produced a fresh verification id.
          setState(() {
            _verificationId = state.verificationId;
            _resendToken = state.resendToken;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("A new code has been sent")),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Text(
                    "Verify OTP",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 260,
                    child: Text(
                      "Enter the 6-digit code sent to ${widget.phoneNumber}",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        "Invalid code. Please try again.",
                        style: TextStyle(color: scheme.error),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_otpLength, (index) {
                      final isFilled = _controllers[index].text.isNotEmpty;
                      final borderColor = _hasError
                          ? scheme.error
                          : (isFilled ? scheme.primary : scheme.outline);
                      return SizedBox(
                        width: 48,
                        height: 56,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: theme.textTheme.titleLarge,
                          cursorColor: scheme.primary,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: "",
                            filled: false,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: borderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: _hasError ? scheme.error : scheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) => _onChanged(value, index),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        );
                      }
                      return TextButton(
                        onPressed: _resend,
                        child: const Text("Resend OTP"),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
