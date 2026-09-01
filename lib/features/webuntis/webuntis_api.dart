import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'webuntis_models.dart';
import 'webuntis_otp.dart';

/// Why a WebUntis call failed, mapped onto something a teacher can act on.
///
/// The numeric codes are the ones Untis documents for its mobile endpoint; the
/// transport values have no code on the wire and are raised by this client.
enum WebUntisErrorCode {
  unknown(0, 'webuntis_error_generic'),
  invalidSchool(-8500, 'webuntis_error_school'),
  noSpecifiedUser(-8502, 'webuntis_error_credentials'),
  invalidPassword(-8504, 'webuntis_error_credentials'),
  noRight(-8509, 'webuntis_error_no_right'),
  lockedAccess(-8511, 'webuntis_error_locked'),
  twoFactorRequired(-8519, 'webuntis_error_two_factor'),
  authenticationRequired(-8520, 'webuntis_error_credentials'),
  authenticationError(-8521, 'webuntis_error_credentials'),
  noPublicAccess(-8523, 'webuntis_error_no_right'),
  invalidClientTime(-8524, 'webuntis_error_client_time'),
  methodNotFound(-32601, 'webuntis_error_unsupported'),
  accessDenied(-42000, 'webuntis_error_no_right'),
  accessDeniedApp(-42002, 'webuntis_error_no_right'),
  serverMaintenance(-42003, 'webuntis_error_maintenance'),
  noResult(10000, 'webuntis_error_no_result'),

  /// The request never reached WebUntis, or the answer was not JSON-RPC.
  network(-1000001, 'webuntis_error_network'),
  malformedResponse(-1000002, 'webuntis_error_response'),

  /// The library has no WebUntis connection configured yet.
  notConfigured(-1000003, 'webuntis_not_connected');

  const WebUntisErrorCode(this.code, this.translationKey);

  final int code;

  /// Key into `assets/translations`, so callers can show the reason directly.
  final String translationKey;

  static WebUntisErrorCode fromCode(int? code) {
    for (final value in WebUntisErrorCode.values) {
      if (value.code == code) {
        return value;
      }
    }
    return WebUntisErrorCode.unknown;
  }
}

class WebUntisException implements Exception {
  const WebUntisException(this.errorCode, {this.message, this.rawCode});

  factory WebUntisException.fromRpcError(Map<String, dynamic> error) {
    final code = readInt(error['code']);
    final message = error['message'];
    return WebUntisException(
      WebUntisErrorCode.fromCode(code),
      message: message is String && message.isNotEmpty ? message : null,
      rawCode: code,
    );
  }

  final WebUntisErrorCode errorCode;

  /// The server's own wording. Useful in a log, too vague for a teacher.
  final String? message;

  /// The code as it came off the wire, kept so an unmapped code is still
  /// visible in a bug report.
  final int? rawCode;

  String get translationKey => errorCode.translationKey;

  @override
  String toString() =>
      'WebUntisException(${errorCode.name}, code: ${rawCode ?? errorCode.code}'
      '${message == null ? '' : ', message: $message'})';
}

/// A thin client for the WebUntis mobile JSON-RPC endpoint
/// (`/WebUntis/jsonrpc_intern.do`).
///
/// This is the endpoint the Untis Mobile app itself uses. It is chosen over
/// the public `jsonrpc.do` API on purpose: the public API can list classes but
/// cannot say which students are in one, and it exposes no class register. The
/// mobile endpoint answers both — `getPeriodData2017` returns the students of
/// a lesson together with their absences.
class WebUntisApi {
  WebUntisApi({
    required String server,
    required this.school,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 30),
    this.clientId = 'classi',
    DateTime Function()? clock,
  }) : host = normalizeServer(server),
       _httpClient = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _clock = clock ?? DateTime.now;

  /// Bare host name, e.g. `mese.webuntis.com`.
  final String host;

  /// The school's login name, i.e. the `school` query parameter.
  final String school;

  final Duration timeout;
  final String clientId;

  final http.Client _httpClient;
  final bool _ownsClient;
  final DateTime Function() _clock;

  /// Accepts whatever a teacher pastes out of their browser and reduces it to
  /// a host name: a bare host, a full URL, or a deep link with query
  /// parameters all end up the same.
  static String normalizeServer(String raw) {
    var value = raw.trim();
    if (value.isEmpty) {
      return '';
    }
    if (!value.contains('://')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) {
      return raw.trim();
    }
    return uri.host;
  }

  /// Pulls the `school` query parameter out of a pasted WebUntis URL, so the
  /// teacher does not have to identify it themselves.
  static String? schoolFromUrl(String raw) {
    final value = raw.trim();
    if (!value.contains('://')) {
      return null;
    }
    final uri = Uri.tryParse(value);
    final school = uri?.queryParameters['school'];
    if (school == null || school.isEmpty) {
      return null;
    }
    return school;
  }

  Uri get endpoint =>
      Uri.https(host, '/WebUntis/jsonrpc_intern.do', {'school': school});

  void dispose() {
    if (_ownsClient) {
      _httpClient.close();
    }
  }

  /// Exchanges a password for the long-lived app shared secret.
  ///
  /// Called once while connecting. The password is never persisted; only the
  /// returned secret is, and every later request derives a one-time password
  /// from it.
  Future<String> fetchAppSharedSecret({
    required String username,
    required String password,
  }) async {
    final result = await _call('getAppSharedSecret', {
      'userName': username,
      'password': password,
    });

    if (result is String && result.isNotEmpty) {
      return result;
    }
    throw const WebUntisException(WebUntisErrorCode.malformedResponse);
  }

  /// The signed-in account plus the school's master data (classes, years).
  Future<WebUntisUserData> fetchUserData({
    required String username,
    required String secret,
  }) async {
    final result = await _call('getUserData2017', {
      'elementId': 0,
      'deviceOs': 'AND',
      'deviceOsVersion': '',
      'auth': _auth(username, secret),
    });

    return WebUntisUserData.fromJson(_asMap(result));
  }

  /// The lessons of one element between [from] and [to], inclusive.
  Future<List<WebUntisPeriod>> fetchTimetable({
    required String username,
    required String secret,
    required int elementId,
    required WebUntisElementType elementType,
    required DateTime from,
    required DateTime to,
    int masterDataTimestamp = 0,
  }) async {
    final result = await _call('getTimetable2017', {
      'id': elementId,
      'type': elementType.wireName,
      'startDate': formatWebUntisDate(from),
      'endDate': formatWebUntisDate(to),
      'masterDataTimestamp': masterDataTimestamp,
      'timetableTimestamp': 0,
      'timetableTimestamps': const <int>[],
      'auth': _auth(username, secret),
    });

    final timetable = _asMap(result)['timetable'];
    if (timetable is! Map) {
      return const [];
    }
    return readList(
      Map<String, dynamic>.from(timetable)['periods'],
    ).map(WebUntisPeriod.fromJson).toList(growable: false);
  }

  /// Class register data for the given lessons: who is enrolled and who was
  /// marked absent.
  Future<WebUntisPeriodDataResult> fetchPeriodData({
    required String username,
    required String secret,
    required Iterable<int> periodIds,
  }) async {
    final ids = periodIds.toSet().toList(growable: false);
    if (ids.isEmpty) {
      return const WebUntisPeriodDataResult(
        dataByTtId: {},
        referencedStudents: [],
      );
    }

    final result = await _call('getPeriodData2017', {
      'ttIds': ids,
      'auth': _auth(username, secret),
    });

    return WebUntisPeriodDataResult.fromJson(_asMap(result));
  }

  /// Every absence the account may see between [from] and [to].
  Future<List<WebUntisAbsence>> fetchStudentAbsences({
    required String username,
    required String secret,
    required DateTime from,
    required DateTime to,
    bool includeExcused = true,
    bool includeUnexcused = true,
  }) async {
    final result = await _call('getStudentAbsences2017', {
      'startDate': formatWebUntisDate(from),
      'endDate': formatWebUntisDate(to),
      'includeExcused': includeExcused,
      'includeUnExcused': includeUnexcused,
      'auth': _auth(username, secret),
    });

    return readList(
      _asMap(result)['absences'],
    ).map(WebUntisAbsence.fromJson).toList(growable: false);
  }

  Map<String, dynamic> _auth(String username, String secret) {
    final clientTime = _clock().millisecondsSinceEpoch;
    return {
      'user': username,
      'otp': webUntisOtp(secret: secret, clientTimeMillis: clientTime),
      'clientTime': clientTime,
    };
  }

  Map<String, dynamic> _asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

  Future<Object?> _call(String method, Map<String, dynamic> params) async {
    if (host.isEmpty || school.isEmpty) {
      throw const WebUntisException(WebUntisErrorCode.notConfigured);
    }

    final body = jsonEncode({
      'id': clientId,
      'jsonrpc': '2.0',
      'method': method,
      // WebUntis expects the parameter object wrapped in a single-element
      // list, unlike the public jsonrpc.do endpoint.
      'params': [params],
    });

    http.Response response;
    try {
      response = await _httpClient
          .post(
            endpoint,
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body,
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const WebUntisException(
        WebUntisErrorCode.network,
        message: 'Request timed out',
      );
    } on Object catch (error) {
      throw WebUntisException(
        WebUntisErrorCode.network,
        message: error.toString(),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WebUntisException(
        WebUntisErrorCode.network,
        message: 'HTTP ${response.statusCode}',
      );
    }

    Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const WebUntisException(WebUntisErrorCode.malformedResponse);
    }

    if (decoded is! Map) {
      throw const WebUntisException(WebUntisErrorCode.malformedResponse);
    }

    final envelope = Map<String, dynamic>.from(decoded);
    final error = envelope['error'];
    if (error is Map) {
      throw WebUntisException.fromRpcError(Map<String, dynamic>.from(error));
    }

    if (!envelope.containsKey('result')) {
      throw const WebUntisException(WebUntisErrorCode.malformedResponse);
    }

    return envelope['result'];
  }
}
