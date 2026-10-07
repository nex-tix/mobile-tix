import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/bloc/auth/auth_state.dart';
import '../../../../core/config/app_config.dart';
import '../../../checkpoint/data/dummy_checkpoints.dart';
import '../../../checkpoint/data/models/checkpoint.dart';

/// Sign-in screen based on `newDesign/1._login/code.html`.
///
/// Features:
/// - Brand logo and "Gate Validator" header
/// - Sleek dark obsidian credentials form (`#18202C` fields with amber focus)
/// - Amber gold gradient action button
/// - Atmospheric Uluwatu Kecak fire dance photo background at the bottom
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final TextEditingController _username = TextEditingController(
    text: AppConfig.demoUsername,
  );
  late final TextEditingController _password = TextEditingController(
    text: AppConfig.demoPassword,
  );
  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscured = true;
  String? _usernameError;
  String? _passwordError;
  String? _gateError;
  Checkpoint? _selectedGate = dummyCheckpoints.first;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _submit() {
      final username = _username.text.trim();
      final password = _password.text;
      setState(() {
        _usernameError = username.isEmpty ? 'Username wajib diisi' : null;
        _passwordError = password.isEmpty ? 'Password wajib diisi' : null;
        _gateError = _selectedGate == null ? 'Pilih gate terlebih dahulu' : null;
      });
      if (_usernameError != null || _passwordError != null || _gateError != null) return;

      FocusScope.of(context).unfocus();
      context.read<AuthBloc>().add(
        LoginSubmitted(
          username: username,
          password: password,
        ),
      );
    }

  @override
    Widget build(BuildContext context) {
      final screenHeight = MediaQuery.sizeOf(context).height;
      // Approximately 44% of the screen height to extend up comfortably below the login button
      final bgHeight = (screenHeight * 0.44).clamp(340.0, 520.0);

      return BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: const Color(0xFFCF4647),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Scaffold(
      backgroundColor: const Color(0xFF2A363B),
      body: Stack(
        children: [
          // Background ambient
          Positioned.fill(
            child: Container(
              color: const Color(0xFF2A363B),
            ),
          ),

          // Bottom Kecak Fire Dance Background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: bgHeight,
            child: IgnorePointer(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Kecak photo asset from root folder
                  Image.asset(
                    AppConfig.kecakBackgroundAsset,
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, 0.45),
                  ),
                  // Dark ambient overlay tint to harmonize overall tones
                  Container(
                    color: const Color(0xFF2A363B).withValues(alpha: 0.15),
                  ),
                  // Ultra-smooth multi-stop feathered gradient to seamlessly blend into #2A363B
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [
                            0.0,
                            0.15,
                            0.30,
                            0.48,
                            0.68,
                            0.88,
                            1.0,
                          ],
                          colors: [
                            const Color(0xFF2A363B), // 100% solid at the top
                            const Color(0xFF2A363B), // solid to guarantee no edge
                            const Color(0xEA2A363B), // ~92%
                            const Color(0xB32A363B), // ~70%
                            const Color(0x662A363B), // ~40%
                            const Color(0x1F2A363B), // ~12%
                            Colors.transparent, // vivid fire and sparks
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main form content centered
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 390),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 16),
                            // Brand Logo (diperbesar untuk visibilitas)
                            Container(
                              width: 160,
                              height: 160,
                              alignment: Alignment.center,
                              child: Image.asset(
                                AppConfig.logoAsset,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // App Title
                            const Text(
                              'Gate Validator',
                              style: TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF8F6F6),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Username Input Field
                            _buildInputField(
                              controller: _username,
                              focusNode: _usernameFocus,
                              hint: 'Username',
                              icon: AppIcons.person,
                              obscure: false,
                              error: _usernameError,
                            ),
                            const SizedBox(height: 14),

                            // Password Input Field
                            _buildInputField(
                              controller: _password,
                              focusNode: _passwordFocus,
                              hint: 'Password',
                              icon: AppIcons.lock,
                              obscure: _obscured,
                              error: _passwordError,
                              trailing: IconButton(
                                icon: Icon(
                                  _obscured
                                      ? AppIcons.visibilityOff
                                      : AppIcons.visibility,
                                  color: const Color(0xFFA3B1B7),
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() => _obscured = !_obscured);
                                },
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Gate Dropdown
                            _buildGateDropdown(),
                            const SizedBox(height: 20),

                            // Deep Red Gradient Login Button (Clean, no glow)
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFCF4647),
                                      Color(0xFFB83A3B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: isLoading ? null : _submit,
                                    child: Center(
                                      child: isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2.2,
                                                color: Color(0xFFF8F6F6),
                                              ),
                                            )
                                          : const Text(
                                              'Login',
                                              style: TextStyle(
                                                fontFamily: 'DMSans',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFFF8F6F6),
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Helper demo hint
                            const SizedBox(height: 16),
                            Text(
                              'Gunakan akun demo: ${AppConfig.demoUsername}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFA3B1B7),
                              ),
                            ),
                            const SizedBox(height: 120), // Room for bottom Kecak scene
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
        },
      );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required IconData icon,
    required bool obscure,
    String? error,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF212B2F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? const Color(0xFFCF4647)
                  : focusNode.hasFocus
                  ? const Color(0xFFF5D061)
                  : const Color(0xFF3E4E55),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFA3B1B7),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    color: Color(0xFFF8F6F6),
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      color: Color(0xFF8B9FA8),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCF4647),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildGateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF212B2F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _gateError != null
                  ? const Color(0xFFCF4647)
                  : const Color(0xFF3E4E55),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  AppIcons.door,
                  size: 20,
                  color: const Color(0xFFA3B1B7),
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Checkpoint>(
                    value: _selectedGate,
                    isExpanded: true,
                    hint: const Text(
                      'Pilih Gate',
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        color: Color(0xFF8B9FA8),
                      ),
                    ),
                    items: dummyCheckpoints.map((checkpoint) {
                      return DropdownMenuItem<Checkpoint>(
                        value: checkpoint,
                        child: Text(
                          checkpoint.label,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            color: Color(0xFFF8F6F6),
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedGate = value;
                        _gateError = null;
                      });
                    },
                    dropdownColor: const Color(0xFF212B2F),
                    icon: const Icon(
                      AppIcons.arrowDropDown,
                      color: Color(0xFFA3B1B7),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        if (_gateError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _gateError!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFCF4647),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
