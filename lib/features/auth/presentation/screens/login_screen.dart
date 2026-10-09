import 'package:easy_localization/easy_localization.dart';
import 'package:mobile_tix/core/constants/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/auth/auth_bloc.dart';
import '../../../../core/bloc/auth/auth_event.dart';
import '../../../../core/bloc/auth/auth_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/ui/widgets/app_snackbar.dart';
import '../../../checkpoint/data/dummy_checkpoints.dart';
import '../../../checkpoint/data/models/checkpoint.dart';
import '../../logic/session_state.dart';

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
      _usernameError = username.isEmpty
          ? context.tr('auth.usernameRequired')
          : null;
      _passwordError = password.isEmpty
          ? context.tr('auth.passwordRequired')
          : null;
      _gateError = _selectedGate == null
          ? context.tr('auth.gateRequired')
          : null;
    });
    if (_usernameError != null ||
        _passwordError != null ||
        _gateError != null) {
      return;
    }

    FocusScope.of(context).unfocus();
    context.read<SessionState>().setStaffAndCheckpoint(
      checkpoint: _selectedGate,
    );
    context.read<AuthBloc>().add(
      LoginSubmitted(username: username, password: password),
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
          AppSnackbar.danger(context, state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: context.colors.ground,
          body: Stack(
            children: [
              // Background ambient
              Positioned.fill(child: Container(color: context.colors.ground)),

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
                        color: context.colors.ground.withValues(alpha: 0.15),
                      ),
                      // Feathered gradient to blend the photo into ground
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.0, 0.3, 0.7, 1.0],
                              colors: [
                                context.colors.ground,
                                context.colors.ground.withValues(alpha: 0.85),
                                context.colors.ground.withValues(alpha: 0.35),
                                Colors.transparent,
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
                                Text(
                                  context.tr('auth.appTitle'),
                                  style: TextStyle(
                                    fontFamily: 'DMSans',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.ink,
                                  ),
                                ),
                                const SizedBox(height: 28),

                                // Username Input Field
                                _buildInputField(
                                  controller: _username,
                                  focusNode: _usernameFocus,
                                  hint: context.tr('auth.username'),
                                  icon: AppIcons.person,
                                  obscure: false,
                                  error: _usernameError,
                                ),
                                const SizedBox(height: 14),

                                // Password Input Field
                                _buildInputField(
                                  controller: _password,
                                  focusNode: _passwordFocus,
                                  hint: context.tr('auth.password'),
                                  icon: AppIcons.lock,
                                  obscure: _obscured,
                                  error: _passwordError,
                                  trailing: IconButton(
                                    icon: Icon(
                                      _obscured
                                          ? AppIcons.visibilityOff
                                          : AppIcons.visibility,
                                      color: context.colors.onFieldMuted,
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

                                // Primary Login Button (flat, clean, no glow)
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: context.colors.primary,
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
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : Text(
                                                  context.tr('auth.login'),
                                                  style: TextStyle(
                                                    fontFamily: 'DMSans',
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: context
                                                        .colors
                                                        .onPrimary,
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
                                  context.tr(
                                    'auth.demoHint',
                                    namedArgs: {
                                      'username': AppConfig.demoUsername,
                                    },
                                  ),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colors.inkMuted,
                                  ),
                                ),
                                const SizedBox(
                                  height: 120,
                                ), // Room for bottom Kecak scene
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
            color: context.colors.surfaceField,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: error != null
                  ? context.colors.primary
                  : focusNode.hasFocus
                  ? context.colors.secondary
                  : context.colors.onFieldMuted.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(icon, size: 20, color: context.colors.onFieldMuted),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscure,
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 15,
                    color: context.colors.onField,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 15,
                      color: context.colors.onFieldMuted,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              error,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.primary,
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
            color: context.colors.surfaceField,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _gateError != null
                  ? context.colors.primary
                  : context.colors.onFieldMuted.withValues(alpha: 0.45),
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
                  color: context.colors.onFieldMuted,
                ),
              ),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Checkpoint>(
                    value: _selectedGate,
                    isExpanded: true,
                    hint: Text(
                      context.tr('auth.selectGate'),
                      style: TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 15,
                        color: context.colors.onFieldMuted,
                      ),
                    ),
                    items: dummyCheckpoints.map((checkpoint) {
                      return DropdownMenuItem<Checkpoint>(
                        value: checkpoint,
                        child: Text(
                          checkpoint.label,
                          style: TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 15,
                            color: context.colors.onField,
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
                    dropdownColor: context.colors.surfaceField,
                    icon: Icon(
                      AppIcons.arrowDropDown,
                      color: context.colors.onFieldMuted,
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
              style: TextStyle(
                fontSize: 12,
                color: context.colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
