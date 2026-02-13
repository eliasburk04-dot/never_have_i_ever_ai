import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/supabase_service.dart';
import '../../utils/i18n.dart';
import 'lobby_waiting_screen.dart';

class JoinLobbyScreen extends ConsumerStatefulWidget {
  const JoinLobbyScreen({super.key});

  static const routeName = 'join-lobby';
  static const routePath = '/join';

  @override
  ConsumerState<JoinLobbyScreen> createState() => _JoinLobbyScreenState();
}

class _JoinLobbyScreenState extends ConsumerState<JoinLobbyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _joinLobby() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final service = ref.read(supabaseServiceProvider);

    try {
      final lobby = await service.joinLobby(
        _codeController.text.trim().toUpperCase(),
        _nicknameController.text.trim(),
      );

      if (!mounted) return;
      context.goNamed(
        LobbyWaitingScreen.routeName,
        pathParameters: {'lobbyId': (lobby['id'] ?? '').toString()},
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = I18n.resolveLanguageCode(Localizations.localeOf(context).languageCode);

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('join_lobby', languageCode: languageCode))),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _codeController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: I18n.tr('lobby_code', languageCode: languageCode),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().length < 4) {
                            return I18n.tr('enter_valid_code', languageCode: languageCode);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: I18n.tr('nickname', languageCode: languageCode),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return I18n.tr('enter_nickname', languageCode: languageCode);
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _joinLobby,
                          child: Text(
                            _submitting
                                ? I18n.tr('joining', languageCode: languageCode)
                                : I18n.tr('join', languageCode: languageCode),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
