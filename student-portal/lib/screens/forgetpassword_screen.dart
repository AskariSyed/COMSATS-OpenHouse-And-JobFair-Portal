import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:student_job_fair_portal/provider/student_provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:student_job_fair_portal/utils/password_validator.dart';
import 'package:student_job_fair_portal/screens/sigin.dart';

// ============================================================================
// SCREEN 1: REQUEST OTP (Registration Number Only)
// ============================================================================
class ForgotPasswordRequestScreen extends StatefulWidget {
  const ForgotPasswordRequestScreen({super.key});

  @override
  State<ForgotPasswordRequestScreen> createState() =>
      _ForgotPasswordRequestScreenState();
}

class _ForgotPasswordRequestScreenState
    extends State<ForgotPasswordRequestScreen> {
  final _regNoController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendOtp() async {
    final regNo = _regNoController.text.trim();
    final regNoPattern = RegExp(r'^[A-Z]{2}\d{2}-[A-Z]{3}-\d{3}$');

    if (regNo.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: "Please enter your Registration Number.",
        ),
      );
      return;
    }

    if (!regNoPattern.hasMatch(regNo)) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(
          message: "Use format AA00-AAA-000 (e.g. FA22-BCS-007).",
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);

    try {
      final int userId = await provider.sendPasswordResetOtp(regNo);

      if (!mounted) return;

      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(
          message: "OTP sent to your registered email!",
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ForgotPasswordResetScreen(userId: userId, emailOrRegNo: regNo),
        ),
      );
    } catch (e) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width >= 980;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const brandBlue = Color(0xFF2563EB);
    const brandNavy = Color(0xFF0F172A);
    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF111827) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final titleColor = isDark ? Colors.white : brandNavy;
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : Colors.blueGrey.shade600;
    final fieldFill = isDark
        ? const Color(0xFF1E293B)
        : const Color(0xFFF8FAFC);
    final fieldBorder = isDark
        ? const Color(0xFF475569)
        : const Color(0xFFD1D9E6);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SizedBox(
          height: size.height,
          width: size.width,
          child: Row(
            children: [
              if (isWeb)
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF0B1220),
                          Color(0xFF1E3A8A),
                          Color(0xFF2563EB),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -80,
                          left: -60,
                          child: Container(
                            height: 260,
                            width: 260,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -100,
                          right: -70,
                          child: Container(
                            height: 320,
                            width: 320,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 56,
                            vertical: 42,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: 54,
                                    width: 54,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      color: Colors.white.withOpacity(0.15),
                                    ),
                                    child: Image.asset(
                                      'assets/LogoWithoutBg.png',
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.school,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  const Expanded(
                                    child: Text(
                                      'COMSATS Wah Job Fair',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Text(
                                'Forgot Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  height: 1.08,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Recover your account quickly by verifying your registration number.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.86),
                                  fontSize: 17,
                                  height: 1.45,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Designed for the Open House and Job Fair experience.',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.72),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: Container(
                  color: pageBg,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 54 : 20,
                        vertical: 30,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isWeb ? 480 : 500,
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 30 : 22,
                            vertical: isWeb ? 30 : 24,
                          ),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: isDark
                                    ? const Color(0x22000000)
                                    : const Color(0x1A0F172A),
                                blurRadius: 32,
                                offset: const Offset(0, 14),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isWeb
                                ? CrossAxisAlignment.start
                                : CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 64,
                                height: 64,
                                child: Image.asset(
                                  'assets/LogoWithoutBg.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      Icon(Icons.lock_reset, color: titleColor),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Text(
                                'Forgot Password?',
                                textAlign: isWeb
                                    ? TextAlign.start
                                    : TextAlign.center,
                                style: TextStyle(
                                  fontSize: isWeb ? 34 : 28,
                                  fontWeight: FontWeight.w800,
                                  color: titleColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Enter your registration number and we'll send an OTP to your registered email.",
                                textAlign: isWeb
                                    ? TextAlign.start
                                    : TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: subtitleColor,
                                  height: 1.45,
                                ),
                              ),
                              const SizedBox(height: 26),
                              TextField(
                                controller: _regNoController,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[a-zA-Z0-9-]'),
                                  ),
                                  UpperCaseHyphenFormatter(maxLength: 12),
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Registration Number',
                                  hintText: 'FA22-BCS-155',
                                  labelStyle: TextStyle(color: subtitleColor),
                                  hintStyle: TextStyle(
                                    color: subtitleColor.withOpacity(0.8),
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: brandBlue,
                                  ),
                                  filled: true,
                                  fillColor: fieldFill,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(color: fieldBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(
                                      color: brandBlue,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 26),
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _sendOtp,
                                  style:
                                      ElevatedButton.styleFrom(
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                        elevation: 0,
                                      ).copyWith(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                              Colors.transparent,
                                            ),
                                      ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [brandNavy, brandBlue],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              'Send OTP',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 15,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const StudentLoginScreen(),
                                        ),
                                        (route) => false,
                                      );
                                    },
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: brandBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// SCREEN 2: VERIFY OTP (6-Digits) & RESET
// ============================================================================
class ForgotPasswordResetScreen extends StatefulWidget {
  final int userId;
  final String emailOrRegNo;
  const ForgotPasswordResetScreen({
    super.key,
    required this.userId,
    required this.emailOrRegNo,
  });

  @override
  State<ForgotPasswordResetScreen> createState() =>
      _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  static const int _resendCooldownSeconds = 120;
  final _otpController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  bool _isPassVisible = false;
  bool _isConfirmVisible = false;
  int _resendSecondsLeft = _resendCooldownSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendSecondsLeft = _resendCooldownSeconds;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsLeft <= 1) {
        timer.cancel();
        setState(() {
          _resendSecondsLeft = 0;
        });
      } else {
        setState(() {
          _resendSecondsLeft--;
        });
      }
    });
  }

  String get _resendTimeFormatted {
    final minutes = (_resendSecondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendSecondsLeft % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _resendOtp() async {
    if (_resendSecondsLeft > 0 || _isResending || _isLoading) return;

    setState(() => _isResending = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);

    try {
      await provider.sendPasswordResetOtp(widget.emailOrRegNo);
      if (!mounted) return;

      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(
          message: "A new OTP has been sent to your registered email.",
        ),
      );
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _resetPassword() async {
    final otp = _otpController.text.trim();
    final pass = _passController.text.trim();
    final confirm = _confirmPassController.text.trim();

    if (otp.length != 6) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "OTP must be 6 digits."),
      );
      return;
    }

    if (pass.isEmpty || confirm.isEmpty) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Password fields are required."),
      );
      return;
    }

    // Validate password strength
    final passwordError = PasswordValidator.validate(pass);
    if (passwordError != null) {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: passwordError),
      );
      return;
    }

    if (pass != confirm) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.error(message: "Passwords do not match."),
      );
      return;
    }

    setState(() => _isLoading = true);
    final provider = Provider.of<StudentProvider>(context, listen: false);

    final error = await provider.resetPassword(
      userId: widget.userId,
      otp: otp,
      newPassword: pass,
      confirmPassword: confirm,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (error == null) {
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.success(message: "Password reset successfully!"),
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(message: error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
      resizeToAvoidBottomInset: true,
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            // 1. Gradient Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: size.height * 0.4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.verified_user_outlined,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Set New Password",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Sign In Button
            Positioned(
              top: 40,
              left: 20,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const StudentLoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text(
                  'Sign In',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // 3. Main Card
            Positioned(
              top: size.height * 0.3,
              left: isWeb ? (size.width - 450) / 2 : 20,
              right: isWeb ? (size.width - 450) / 2 : 20,
              bottom: 20,
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.blue.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Check your email",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Enter the 6-digit OTP sent to your email.",
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "OTP expires in 10 minutes",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.blue.shade200
                              : const Color(0xFF1E3C72),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _resendSecondsLeft > 0
                                ? "Resend OTP in $_resendTimeFormatted"
                                : "Didn't receive code?",
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          TextButton(
                            onPressed: _resendSecondsLeft == 0 && !_isResending
                                ? _resendOtp
                                : null,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 28),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: _isResending
                                ? const SizedBox(
                                    height: 14,
                                    width: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Resend OTP",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // 🔹 UPDATED: 6-Digit OTP Style
                      Center(
                        child: SizedBox(
                          width: 200,
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 8,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            decoration: InputDecoration(
                              counterText: "", // Hide counter
                              hintText: "------",
                              hintStyle: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade600
                                    : Colors.grey.shade300,
                                letterSpacing: 8,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF2A2A2A)
                                  : Colors.grey.shade50,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // New Password
                      TextField(
                        controller: _passController,
                        obscureText: !_isPassVisible,
                        decoration: InputDecoration(
                          labelText: "New Password",
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPassVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _isPassVisible = !_isPassVisible,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade50,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      TextField(
                        controller: _confirmPassController,
                        obscureText: !_isConfirmVisible,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          prefixIcon: const Icon(Icons.lock_reset),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () => setState(
                              () => _isConfirmVisible = !_isConfirmVisible,
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade50,
                        ),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _resetPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3C72),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "RESET PASSWORD",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 HELPER: Strict formatter for AA00-AAA-000
class UpperCaseHyphenFormatter extends TextInputFormatter {
  final int maxLength;
  UpperCaseHyphenFormatter({required this.maxLength});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawInput = newValue.text.toUpperCase().replaceAll('-', '');
    final buffer = StringBuffer();

    for (final char in rawInput.split('')) {
      final index = buffer.length;
      if (index >= 10) break;

      final isLetter = RegExp(r'[A-Z]').hasMatch(char);
      final isDigit = RegExp(r'\d').hasMatch(char);

      final shouldBeLetter = index < 2 || (index >= 4 && index <= 6);
      final shouldBeDigit = (index >= 2 && index <= 3) || index >= 7;

      if ((shouldBeLetter && isLetter) || (shouldBeDigit && isDigit)) {
        buffer.write(char);
      }
    }

    final filtered = buffer.toString();
    final formatted = StringBuffer();

    for (int i = 0; i < filtered.length; i++) {
      if (i == 4 || i == 7) formatted.write('-');
      formatted.write(filtered[i]);
    }

    String result = formatted.toString();
    if (result.length > maxLength) {
      result = result.substring(0, maxLength);
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: result.length),
    );
  }
}
