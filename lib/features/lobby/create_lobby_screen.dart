import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/statement.dart';
import '../../services/supabase_service.dart';
import '../../utils/i18n.dart';
import 'lobby_waiting_screen.dart';

class CreateLobbyScreen extends ConsumerStatefulWidget {
  const CreateLobbyScreen({super.key});

  static const routeName = 'create-lobby';
  static const routePath = '/create';

  @override
  ConsumerState<CreateLobbyScreen> createState() => _CreateLobbyScreenState();
}

class _CreateLobbyScreenState extends ConsumerState<CreateLobbyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController(text: 'Host');

  StatementLanguage _language = StatementLanguage.en;
  int _roundLimit = 5;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _createLobby() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final service = ref.read(supabaseServiceProvider);

    try {
      final lobby = await service.createLobby(_language.code, _roundLimit);
      final lobbyId = (lobby['id'] ?? '').toString();

      final nickname = _nicknameController.text.trim();
      await service.joinLobby((lobby['code'] ?? '').toString(), nickname);

      if (!mounted) return;
      context.goNamed(
        LobbyWaitingScreen.routeName,
        pathParameters: {'lobbyId': lobbyId},
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
    final languageCode = _language.code;

    return Scaffold(
      appBar: AppBar(title: Text(I18n.tr('create_lobby', languageCode: languageCode))),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nicknameController,
                        decoration: InputDecoration(
                          labelText: I18n.tr('your_nickname', languageCode: languageCode),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return I18n.tr('enter_nickname', languageCode: languageCode);
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<StatementLanguage>(
                        initialValue: _language,
                        decoration: InputDecoration(
                          labelText: I18n.tr('language', languageCode: languageCode),
                        ),
                        items: StatementLanguage.values
                            .map(
                              (language) => DropdownMenuItem(
                                value: language,
                                child: Text(language.code.toUpperCase()),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _language = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Text('${I18n.tr('round_limit', languageCode: languageCode)}: $_roundLimit'),
                      Slider(
                        value: _roundLimit.toDouble(),
                        min: 3,
                        max: 12,
                        divisions: 9,
                        label: _roundLimit.toString(),
                        onChanged: (value) => setState(() => _roundLimit = value.round()),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitting ? null : _createLobby,
                          child: Text(
                            _submitting
                                ? I18n.tr('creating', languageCode: languageCode)
                                : I18n.tr('create', languageCode: languageCode),
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
