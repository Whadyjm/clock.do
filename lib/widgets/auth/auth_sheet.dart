import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/clock_provider.dart';
import '../../services/supabase_config.dart';
import '../../services/supabase_service.dart';

/// Modos de visualización del modal de autenticación
enum AuthSheetMode {
  signIn,
  signUp,
  forgotPassword,
  resetPassword,
}

/// Modal de autenticación y perfil de usuario con Supabase para Clock.Do.
class AuthSheet extends StatefulWidget {
  final AuthSheetMode initialMode;
  final String? initialEmail;

  const AuthSheet({
    super.key,
    this.initialMode = AuthSheetMode.signIn,
    this.initialEmail,
  });

  @override
  State<AuthSheet> createState() => _AuthSheetState();
}

class _AuthSheetState extends State<AuthSheet> {
  late AuthSheetMode _mode;
  final _formKey = GlobalKey<FormState>();
  final _forgotFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmNewPasswordCtrl = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmNewPassword = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (_mode == AuthSheetMode.signUp) {
      _isSignUp = true;
    }
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailCtrl.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmNewPasswordCtrl.dispose();
    super.dispose();
  }

  /// Convierte excepciones técnicas de Supabase o de red en mensajes amigables en español.
  String _humanizeError(dynamic e) {
    final raw = e.toString().toLowerCase();

    // ── Errores de conectividad / DNS / red ──────────────────────────────────
    if (e is SocketException ||
        raw.contains('socketexception') ||
        raw.contains('failed host lookup') ||
        raw.contains('no address associated') ||
        raw.contains('clientexception') ||
        raw.contains('connection refused') ||
        raw.contains('network is unreachable') ||
        raw.contains('errno = 7') ||
        raw.contains('errno = 101') ||
        raw.contains('errno = 111')) {
      return 'Sin conexión a internet. Verifica tu red Wi-Fi o datos móviles e inténtalo de nuevo.';
    }

    // ── Tiempo de espera agotado ─────────────────────────────────────────────
    if (raw.contains('timeout') || raw.contains('timed out')) {
      return 'La conexión tardó demasiado. Verifica tu internet e inténtalo de nuevo.';
    }

    // ── AuthException de Supabase ────────────────────────────────────────────
    if (e is AuthException) {
      final msg = e.message.toLowerCase();

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid email or password') ||
          msg.contains('wrong password')) {
        return 'Correo o contraseña incorrectos. Verifica tus datos e inténtalo de nuevo.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Confirma tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada.';
      }
      if (msg.contains('user not found') || msg.contains('no user found')) {
        return 'No encontramos una cuenta con ese correo. ¿Quieres crear una cuenta nueva?';
      }
      if (msg.contains('email already registered') ||
          msg.contains('user already registered') ||
          msg.contains('already been registered')) {
        return 'Ya existe una cuenta con este correo. Intenta iniciar sesión.';
      }
      if (msg.contains('password should be at least') ||
          msg.contains('password is too short')) {
        return 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (msg.contains('signup is disabled')) {
        return 'El registro está temporalmente desactivado. Inténtalo más tarde.';
      }
      if (msg.contains('otp') || msg.contains('token')) {
        return 'El código ingresado no es válido o ya expiró. Solicita uno nuevo.';
      }
      if (msg.contains('rate limit') || msg.contains('too many requests')) {
        return 'Demasiados intentos seguidos. Espera unos minutos antes de volver a intentarlo.';
      }
      // Si tiene un mensaje en inglés no cubierto, lo retornamos limpio
      return 'Error de autenticación. Verifica tus datos e inténtalo de nuevo.';
    }

    // ── Error genérico ───────────────────────────────────────────────────────
    return 'Algo salió mal. Verifica tu conexión e inténtalo de nuevo.';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final supabaseService = SupabaseService();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      if (_isSignUp) {
        final res = await supabaseService.signUp(
          email: email,
          password: password,
        );
        if (mounted) {
          if (res.session != null) {
            _successMessage = '¡Cuenta creada con éxito!';
            HapticFeedback.heavyImpact();
            context.read<ClockProvider>().syncWithCloud();
          } else {
            _successMessage =
                '¡Cuenta creada! Revisa tu correo para confirmar tu cuenta.';
          }
        }
      } else {
        await supabaseService.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          _successMessage = '¡Bienvenido de nuevo!';
          HapticFeedback.heavyImpact();
          context.read<ClockProvider>().syncWithCloud();
        }
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _humanizeError(e);
      });
      HapticFeedback.vibrate();
    } catch (e) {
      setState(() {
        _errorMessage = _humanizeError(e);
      });
      HapticFeedback.vibrate();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSendRecoveryCode({bool isResend = false}) async {
    final l10n = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = l10n.invalidCredentialsError;
        _successMessage = null;
      });
      HapticFeedback.vibrate();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await SupabaseService().resetPasswordForEmail(email);
      if (mounted) {
        setState(() {
          _successMessage = l10n.recoveryEmailSent;
          _mode = AuthSheetMode.resetPassword;
        });
        HapticFeedback.lightImpact();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e);
        });
        HapticFeedback.vibrate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e);
        });
        HapticFeedback.vibrate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _extractToken(String input) {
    final trimmed = input.trim();
    if (trimmed.contains('token=')) {
      try {
        final uri = Uri.parse(trimmed);
        final token = uri.queryParameters['token'];
        if (token != null && token.isNotEmpty) return token;
      } catch (_) {}
      final match = RegExp(r'token=([^&#\s]+)').firstMatch(trimmed);
      if (match != null) return match.group(1)!;
    }
    return trimmed;
  }

  Future<void> _handleResetPasswordWithOtp() async {
    final l10n = AppLocalizations.of(context);
    if (!_resetFormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailCtrl.text.trim();
    final input = _otpCtrl.text.trim();
    final newPassword = _newPasswordCtrl.text.trim();

    try {
      // Si el usuario pegó la URL completa del enlace del correo
      if (input.startsWith('http://') || input.startsWith('https://')) {
        final uri = Uri.parse(input);
        bool sessionSet = false;
        try {
          final res = await SupabaseService().client?.auth.getSessionFromUrl(uri);
          if (res?.session != null) {
            sessionSet = true;
          }
        } catch (_) {}

        if (!sessionSet) {
          final token = _extractToken(input);
          await SupabaseService().verifyRecoveryOtp(email: email, token: token);
        }
      } else {
        // Si ingresó el código numérico OTP o token extraído
        final token = _extractToken(input);
        await SupabaseService().verifyRecoveryOtp(email: email, token: token);
      }

      await SupabaseService().updatePassword(newPassword);

      if (mounted) {
        setState(() {
          _successMessage = l10n.passwordResetSuccess;
          _mode = AuthSheetMode.signIn;
          _isSignUp = false;
        });
        HapticFeedback.heavyImpact();
        context.read<ClockProvider>().syncWithCloud();
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e);
        });
        HapticFeedback.vibrate();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _humanizeError(e);
        });
        HapticFeedback.vibrate();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSignOut() async {
    final l10n = AppLocalizations.of(context);
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.signOutButton),
        content: Text(
          isSpanish
              ? '¿Estás seguro de que deseas cerrar sesión? Tus tareas en la nube permanecerán guardadas de forma segura en tu cuenta.'
              : 'Are you sure you want to sign out? Your cloud data will remain safely stored in your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(isSpanish ? 'Cancelar' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF7675),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.signOutButton),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<ClockProvider>().signOut();
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClockProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final isConfigured = SupabaseConfig.isConfigured;
    final currentUser = SupabaseService().currentUser;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding + bottomInset),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle de arrastre
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2D42)
                      : const Color(0xFFDDD9F5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Logo oficial Clock.Do
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Image.asset(
                  'assets/clickdologo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            if (!isConfigured) ...[
              _buildConfigNotice(context, isDark, textColor),
            ] else if (currentUser != null) ...[
              _buildUserProfile(context, currentUser, provider, isDark, textColor),
            ] else if (_mode == AuthSheetMode.forgotPassword) ...[
              _buildForgotPasswordForm(context, isDark, textColor),
            ] else if (_mode == AuthSheetMode.resetPassword) ...[
              _buildResetPasswordForm(context, isDark, textColor),
            ] else ...[
              _buildAuthForm(context, isDark, textColor),
            ],
          ],
        ),
      ),
    );
  }

  /// Aviso de configuración pendiente si faltan las credenciales
  Widget _buildConfigNotice(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.cloud_sync_rounded,
            size: 44,
            color: Color(0xFF6C5CE7),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Configura tu Supabase',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Para habilitar el registro, inicio de sesión y sincronización en la nube, añade tus credenciales en lib/services/supabase_config.dart o mediante variables de entorno.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pasos rápidos:',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Crea un proyecto en supabase.com\n2. Ejecuta el script docs/supabase_schema.sql en el SQL Editor\n3. Pega tu Project URL y Anon Key en supabase_config.dart',
                style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF4A4E69),
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Vista de usuario conectado
  Widget _buildUserProfile(
    BuildContext context,
    User user,
    ClockProvider provider,
    bool isDark,
    Color textColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Mi Cuenta',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CEC9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Sincronizado',
                          style: TextStyle(
                            color: Color(0xFF00CEC9),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email ?? 'Usuario',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFF9E98D4)
                          : const Color(0xFF636E72),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Tarjeta de estado de sincronización
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2D42) : const Color(0xFFE8E4FF),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        color: const Color(0xFF6C5CE7),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Copia en la Nube',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (provider.isCloudSyncing)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF6C5CE7)),
                      ),
                    )
                  else
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00CEC9),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Bloques de Reloj',
                      value: '${provider.allBlocks.length}',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricPill(
                      label: 'Tareas ToDo',
                      value: '${provider.todoItems.length}',
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Botón Forzar Sincronización
        ElevatedButton.icon(
          onPressed: provider.isCloudSyncing
              ? null
              : () async {
                  HapticFeedback.selectionClick();
                  await provider.syncWithCloud();
                },
          icon: const Icon(Icons.sync_rounded, size: 20),
          label: Text(
            provider.isCloudSyncing
                ? 'Sincronizando...'
                : 'Sincronizar Datos Ahora',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C5CE7),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),

        const SizedBox(height: 10),

        OutlinedButton.icon(
          onPressed: _handleSignOut,
          icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFFFF7675)),
          label: const Text(
            'Cerrar Sesión',
            style: TextStyle(
              color: Color(0xFFFF7675),
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFF7675), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricPill({
    required String label,
    required String value,
    required bool isDark,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13162B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  /// Formulario de Login / Registro
  Widget _buildAuthForm(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selector de pestaña Login / Registro
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1D2E) : const Color(0xFFF7F6FD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isSignUp = false;
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: !_isSignUp
                            ? const Color(0xFF6C5CE7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Iniciar Sesión',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_isSignUp
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF9E98D4)
                                  : const Color(0xFF636E72)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _isSignUp = true;
                        _errorMessage = null;
                        _successMessage = null;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _isSignUp
                            ? const Color(0xFF6C5CE7)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Crear Cuenta',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isSignUp
                              ? Colors.white
                              : (isDark
                                  ? const Color(0xFF9E98D4)
                                  : const Color(0xFF636E72)),
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Feedback de Mensajes
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7675).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF7675).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF7675), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFF7675),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_successMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00CEC9).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF00CEC9), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF00CEC9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Campo Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              prefixIcon: Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),

          const SizedBox(height: 12),

          // Campo Contraseña
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Contraseña',
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Ingresa una contraseña';
              }
              if (val.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),

          if (_isSignUp) ...[
            const SizedBox(height: 12),
            // Confirmar Contraseña
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscurePassword,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Confirmar Contraseña',
                prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
              ),
              validator: (val) {
                if (_isSignUp && val != _passwordCtrl.text) {
                  return 'Las contraseñas no coinciden';
                }
                return null;
              },
            ),
          ],

          if (!_isSignUp) ...[
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _mode = AuthSheetMode.forgotPassword;
                          _errorMessage = null;
                          _successMessage = null;
                        });
                      },
                child: const Text(
                  '¿Olvidaste tu contraseña?',
                  style: TextStyle(
                    color: Color(0xFF6C5CE7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ] else
            const SizedBox(height: 16),

          const SizedBox(height: 8),

          // Botón Principal
          ElevatedButton(
            onPressed: _isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    _isSignUp ? 'Crear Cuenta' : 'Iniciar Sesión',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Diálogo para cambiar contraseña cuando el usuario ya está autenticado
  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? localError;

    await showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            final textColor = isDark ? Colors.white : const Color(0xFF1E1B4B);

            return AlertDialog(
              backgroundColor: Theme.of(ctx).cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: Color(0xFF6C5CE7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.changePasswordTitle,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (localError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF7675).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: Color(0xFFFF7675), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  localError!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF7675),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: obscureNew,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: l10n.newPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureNew
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureNew = !obscureNew;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Ingresa una contraseña';
                          }
                          if (val.length < 6) {
                            return 'Debe tener al menos 6 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: obscureConfirm,
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          labelText: l10n.confirmNewPasswordLabel,
                          prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscureConfirm
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 18,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                obscureConfirm = !obscureConfirm;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val != newPassCtrl.text) {
                            return l10n.passwordsDoNotMatch;
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(dialogCtx).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() {
                            isSaving = true;
                            localError = null;
                          });

                          try {
                            await SupabaseService().updatePassword(newPassCtrl.text.trim());
                            HapticFeedback.heavyImpact();
                            if (dialogCtx.mounted) {
                              Navigator.of(dialogCtx).pop();
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.passwordResetSuccess,
                                  ),
                                  backgroundColor: const Color(0xFF00CEC9),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                              localError = 'Error al actualizar contraseña: $e';
                            });
                            HapticFeedback.vibrate();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.resetPasswordButton),
                ),
              ],
            );
          },
        );
      },
    );

    newPassCtrl.dispose();
    confirmPassCtrl.dispose();
  }

  /// Formulario para solicitar código OTP o enlace de recuperación
  Widget _buildForgotPasswordForm(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _forgotFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _mode = AuthSheetMode.signIn;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.forgotPasswordTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Icono ilustrativo y texto guía
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C5CE7), Color(0xFFA29BFE)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C5CE7).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_reset_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.forgotPasswordSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Feedback de Mensajes
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7675).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF7675).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF7675), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFF7675),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_successMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00CEC9).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF00CEC9), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF00CEC9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Campo Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 18),

          // Botón Enviar Código
          ElevatedButton(
            onPressed: _isLoading ? null : () => _handleSendRecoveryCode(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n.sendRecoveryEmailButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Botón "¿Ya tienes un código? Ingrésalo aquí"
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _mode = AuthSheetMode.resetPassword;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              child: Text(
                l10n.alreadyHaveOtp,
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Volver al login
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _mode = AuthSheetMode.signIn;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              child: Text(
                l10n.backToSignIn,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Formulario para ingresar código OTP y nueva contraseña
  Widget _buildResetPasswordForm(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    final l10n = AppLocalizations.of(context);

    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _mode = AuthSheetMode.forgotPassword;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  l10n.resetPasswordTitle,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Icono ilustrativo y texto guía
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00CEC9), Color(0xFF81ECEC)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00CEC9).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.vpn_key_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l10n.resetPasswordSubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Feedback de Mensajes
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFF7675).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFF7675).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: Color(0xFFFF7675), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: Color(0xFFFF7675),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          if (_successMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF00CEC9).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF00CEC9).withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Color(0xFF00CEC9), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(
                        color: Color(0xFF00CEC9),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Campo Email
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.emailLabel,
              prefixIcon: const Icon(Icons.email_outlined, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Ingresa tu correo electrónico';
              }
              if (!val.contains('@') || !val.contains('.')) {
                return 'Ingresa un correo válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Campo Código OTP / Token
          TextFormField(
            controller: _otpCtrl,
            keyboardType: TextInputType.text,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              labelText: l10n.otpCodeLabel,
              hintText: 'Código (ej: 123456) o enlace',
              prefixIcon: const Icon(Icons.pin_rounded, size: 20),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Ingresa el código OTP o enlace';
              }
              final extracted = _extractToken(val);
              if (extracted.length < 6) {
                return 'El código debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Campo Nueva Contraseña
          TextFormField(
            controller: _newPasswordCtrl,
            obscureText: _obscureNewPassword,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.newPasswordLabel,
              prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureNewPassword = !_obscureNewPassword;
                  });
                },
              ),
            ),
            validator: (val) {
              if (val == null || val.isEmpty) {
                return 'Ingresa una nueva contraseña';
              }
              if (val.length < 6) {
                return 'La contraseña debe tener al menos 6 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Confirmar Nueva Contraseña
          TextFormField(
            controller: _confirmNewPasswordCtrl,
            obscureText: _obscureConfirmNewPassword,
            style: TextStyle(color: textColor, fontSize: 14),
            decoration: InputDecoration(
              labelText: l10n.confirmNewPasswordLabel,
              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmNewPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmNewPassword = !_obscureConfirmNewPassword;
                  });
                },
              ),
            ),
            validator: (val) {
              if (val != _newPasswordCtrl.text) {
                return l10n.passwordsDoNotMatch;
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Botón Restablecer Contraseña
          ElevatedButton(
            onPressed: _isLoading ? null : _handleResetPasswordWithOtp,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              backgroundColor: const Color(0xFF6C5CE7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    l10n.resetPasswordButton,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
          ),
          const SizedBox(height: 12),

          // Reenviar OTP
          Center(
            child: TextButton(
              onPressed: _isLoading ? null : () => _handleSendRecoveryCode(isResend: true),
              child: Text(
                l10n.resendOtp,
                style: const TextStyle(
                  color: Color(0xFF6C5CE7),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // Volver a Iniciar Sesión
          Center(
            child: TextButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _mode = AuthSheetMode.signIn;
                  _errorMessage = null;
                  _successMessage = null;
                });
              },
              child: Text(
                l10n.backToSignIn,
                style: TextStyle(
                  color: isDark ? const Color(0xFF9E98D4) : const Color(0xFF636E72),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
