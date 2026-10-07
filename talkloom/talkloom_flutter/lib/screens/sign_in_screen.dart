import 'package:flutter/material.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/providers.dart';

import '../client.dart';

class SignInScreen extends ConsumerStatefulWidget {
  final Widget child;
  const SignInScreen({super.key, this.child = const SizedBox.shrink()});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  bool _isSignedIn = false;
  bool? _isGuest;
  Client? _accountClient;
  EmailAuthController? _emailController;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    client.auth.authInfoListenable.addListener(_updateSignedInState);
    _isSignedIn = client.auth.isAuthenticated;
    _loadAccountState();
  }

  @override
  void dispose() {
    _emailController?.dispose();
    _accountClient?.close();
    client.auth.authInfoListenable.removeListener(_updateSignedInState);
    super.dispose();
  }

  void _updateSignedInState() {
    ref.invalidate(sourcesProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(learnerStateProvider);
    ref.invalidate(selectedSourceProvider);
    ref.invalidate(activeLessonProvider);
    setState(() {
      _isSignedIn = client.auth.isAuthenticated;
    });
    _loadAccountState();
  }

  Future<void> _loadAccountState() async {
    try {
      final guest = client.auth.isAuthenticated
          ? await client.anonymousIdp.isGuest()
          : true;
      final account = Client(await serverUrl)
        ..authSessionManager = FlutterAuthSessionManager(
          storage: MemoryAuthStorage(),
        );
      await account.auth.initialize();
      if (!mounted) {
        account.close();
        return;
      }
      _emailController?.dispose();
      _accountClient?.close();
      final controller =
          EmailAuthController(
            client: account,
            startScreen: EmailFlowScreen.login,
            onAuthenticated: _finishUpgrade,
            onError: (_) {
              if (mounted) {
                setState(
                  () => _error = 'Please check your details and try again.',
                );
              }
            },
          )..addListener(() {
            if (mounted) setState(() {});
          });
      setState(() {
        _isGuest = guest;
        _accountClient = account;
        _emailController = controller;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isGuest = true;
          _error = 'Could not reach the server. You can retry as a guest.';
        });
      }
    }
  }

  Future<void> _continueGuest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ensurePrivateSession();
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not connect. Please retry.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finishUpgrade() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final account = _accountClient!.auth.authInfo!;
      if (client.auth.isAuthenticated && await client.anonymousIdp.isGuest()) {
        await client.anonymousIdp.upgrade(account.token);
      }
      await client.auth.updateSignedInUser(account);
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      ref.invalidate(learnerStateProvider);
      if (mounted) context.go('/');
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Your guest learning is safe. Account conversion failed; please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final controller = _emailController;
    final registered = _isSignedIn && _isGuest == false;
    final registration =
        controller?.currentScreen == EmailFlowScreen.startRegistration;
    final primaryScreens =
        registration || controller?.currentScreen == EmailFlowScreen.login;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          tooltip: 'Back to learning',
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Icon(
                            registered
                                ? LucideIcons.shieldCheck
                                : LucideIcons.bookOpen,
                            size: 28,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          registered
                              ? 'You’re signed in'
                              : 'Take your German with you',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          registered
                              ? 'Your learning is connected to your account.'
                              : 'Keep your words and practice across devices.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_isGuest == null)
                          const Center(child: CircularProgressIndicator())
                        else if (registered) ...[
                          widget.child,
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () async {
                                    await client.auth.signOutDevice();
                                    await _continueGuest();
                                  },
                            icon: const Icon(LucideIcons.logOut, size: 18),
                            label: const Text('Sign out'),
                          ),
                        ] else if (controller != null) ...[
                          if (primaryScreens) ...[
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment(
                                  value: false,
                                  label: Text('Sign in'),
                                ),
                                ButtonSegment(
                                  value: true,
                                  label: Text('Create account'),
                                ),
                              ],
                              selected: {registration},
                              showSelectedIcon: false,
                              onSelectionChanged: _busy
                                  ? null
                                  : (value) {
                                      setState(() => _error = null);
                                      controller.navigateTo(
                                        value.single
                                            ? EmailFlowScreen.startRegistration
                                            : EmailFlowScreen.login,
                                      );
                                    },
                            ),
                            const SizedBox(height: 20),
                          ],
                          IgnorePointer(
                            ignoring: _busy,
                            child: Theme(
                              data: theme.copyWith(
                                textTheme: theme.textTheme.copyWith(
                                  headlineMedium: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              child: AnimatedSize(
                                duration: const Duration(milliseconds: 220),
                                alignment: Alignment.topCenter,
                                child: SizedBox(
                                  height: registration ? 220 : 330,
                                  child: EmailSignInWidget(
                                    controller: controller,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_accountClient?.auth.isAuthenticated == true)
                            TextButton(
                              onPressed: _busy ? null : _finishUpgrade,
                              child: const Text('Retry saving my learning'),
                            ),
                        ],
                        if (_busy) const LinearProgressIndicator(),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              _error!,
                              style: TextStyle(color: colors.error),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _busy ? null : _continueGuest,
                    icon: const Icon(LucideIcons.arrowLeft, size: 16),
                    label: Text(
                      _isSignedIn ? 'Back to learning' : 'Continue as guest',
                    ),
                  ),
                  if (!registered)
                    Text(
                      'An account is optional. Your guest learning stays with you.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
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
