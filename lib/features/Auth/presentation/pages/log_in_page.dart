import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import 'otp_page.dart';

class LogInPage extends StatefulWidget {
  const LogInPage({super.key});

  @override
  State<LogInPage> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _phoneNumberController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  PhoneNumber number = PhoneNumber(isoCode: 'ET');
  late String _number = "";
  bool _isValid = false; // Tracks phone number validation

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    });
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        // Only push the OTP page from the login route itself; guards against a
        // resend (which re-emits OtpSent) stacking a second OtpPage on top.
        final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
        if (state is OtpSent && isCurrent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpPage(
                verificationId: state.verificationId,
                forceResendingToken: state.resendToken,
                phoneNumber: _number,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 100),
                Container(
                  width: 84,
                  height: 84,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B6EF5), Color(0xFF9B5BF5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: 260,
                  child: Column(
                    children: [
                      Text(
                        "Your Phone Number",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Please confirm your country code and enter your phone number.",
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    if (state is AuthFailure) {
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 20, bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: scheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.message,
                                style: TextStyle(
                                  color: scheme.onErrorContainer,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox(height: 30);
                  },
                ),
                Form(
                  key: _formKey,
                  child: InternationalPhoneNumberInput(
                    focusNode: _phoneFocusNode,
                    onInputChanged: (PhoneNumber number) {
                      _number = number.phoneNumber ?? "";
                    },
                    onInputValidated: (bool isValid) {
                      setState(() {
                        _isValid = isValid;
                      });
                    },
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.DIALOG,
                      showFlags: true,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.disabled,
                    initialValue: number,
                    textFieldController: _phoneNumberController,
                    formatInput: true,
                    inputDecoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
                    cursorColor: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final enabled = !isLoading && _isValid && _number.isNotEmpty;
            return FloatingActionButton(
              onPressed: enabled
                  ? () => context.read<AuthBloc>().add(AuthRequestOtp(_number))
                  : null,
              backgroundColor: enabled
                  ? scheme.primary
                  : scheme.surfaceContainerHighest,
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      Icons.arrow_forward,
                      size: 32,
                      color: enabled ? Colors.white : scheme.onSurfaceVariant,
                    ),
            );
          },
        ),
      ),
    );
  }
}
