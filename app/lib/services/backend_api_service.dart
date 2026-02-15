import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/env.dart';
import 'backend_session_service.dart';

class BackendApiService {
  BackendApiService(
    this._session, {
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final BackendSessionService _session;
  final http.Client _http;

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final base = Env.apiBaseUri;
    final resolved = base.resolve(path.startsWith('/') ? path : '/$path');
    if (query == null || query.isEmpty) return resolved;
    return resolved.replace(
      queryParameters: {
        ...resolved.queryParameters,
        ...query.map((k, v) => MapEntry(k, '$v')),
      },
    );
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    bool auth = true,
    Map<String, dynamic>? query,
  }) async {
    BackendSession? session;
    if (auth) session = await _session.ensureSession();

    http.Response res = await _http.get(
      _uri(path, query),
      headers: {
        'Accept': 'application/json',
        if (auth) 'Authorization': 'Bearer ${session!.jwt}',
      },
    );

    if (auth && res.statusCode == 401) {
      session = await _session.ensureSession(forceRefresh: true);
      res = await _http.get(
        _uri(path, query),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer ${session.jwt}',
        },
      );
    }

    return _decodeOrThrow(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    bool auth = true,
    Map<String, dynamic>? body,
  }) async {
    BackendSession? session;
    if (auth) session = await _session.ensureSession();

    http.Response res = await _http.post(
      _uri(path),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (auth) 'Authorization': 'Bearer ${session!.jwt}',
      },
      body: jsonEncode(body ?? const {}),
    );

    if (auth && res.statusCode == 401) {
      session = await _session.ensureSession(forceRefresh: true);
      res = await _http.post(
        _uri(path),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.jwt}',
        },
        body: jsonEncode(body ?? const {}),
      );
    }

    return _decodeOrThrow(res);
  }

  Map<String, dynamic> _decodeOrThrow(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final text = res.body;
      throw Exception(
        'API error (${res.statusCode})${text.isNotEmpty ? ': $text' : ''}',
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw Exception('Unexpected API response');
  }
}

