import 'dart:convert';

const _serialKeys = {
  'sn',
  'sensor_sn',
  'sensorsn',
  'sensorserial',
  'sensorserialnumber',
  'serial',
  'serialnumber',
  'device_sn',
  'devicesn',
  'deviceserial',
  'deviceid',
  'sensorid',
  'code',
};

const _ignoredPathTokens = {
  'activate',
  'activation',
  'bind',
  'cgm',
  'connect',
  'device',
  'devices',
  'pair',
  'qr',
  'scan',
  'sensor',
  'sensors',
};

const _modelPrefixByGtin = {'06975022537510': 'D115W'};

String? parseSensorSerialFromQr(String rawValue) {
  final raw = rawValue.trim();
  if (raw.isEmpty) return null;

  final fromJson = _serialFromJson(raw);
  if (fromJson != null) return fromJson;

  final fromGs1 = _serialFromGs1(raw);
  if (fromGs1 != null) return fromGs1;

  final fromLabel = _serialFromLabeledText(raw);
  if (fromLabel != null) return fromLabel;

  final uri = Uri.tryParse(raw);
  if (uri != null) {
    final fromQuery = _serialFromQuery(uri);
    if (fromQuery != null) return fromQuery;

    final fromPath = _serialFromPath(uri);
    if (fromPath != null) return fromPath;
  }

  return normalizeSensorSerial(raw);
}

String? normalizeSensorSerial(String? value) {
  if (value == null) return null;

  var candidate = value.trim();
  if (candidate.isEmpty) return null;

  candidate = Uri.decodeComponent(candidate);
  candidate = candidate.trim().replaceAll(RegExp(r"""^[\s"'<({\[]+"""), '');
  candidate = candidate.replaceAll(RegExp(r"""[\s"',;>)}\]]+$"""), '');
  candidate = candidate.replaceAll(RegExp(r'\s+'), '');

  final labelMatch = RegExp(
    r'^(?:sn|serial(?:number)?|sensor(?:sn|id|serial)?|device(?:sn|id|serial)?|code)[:=#]+(.+)$',
    caseSensitive: false,
  ).firstMatch(candidate);
  if (labelMatch != null) {
    candidate = labelMatch.group(1)!.trim();
  }

  candidate = candidate.replaceAll(RegExp(r'^[^A-Za-z0-9]+'), '');
  candidate = candidate.replaceAll(RegExp(r'[^A-Za-z0-9_-]+$'), '');

  if (!_isSerialCandidate(candidate)) return null;
  return candidate.toUpperCase();
}

String? _serialFromJson(String raw) {
  if (!raw.startsWith('{') && !raw.startsWith('[')) return null;

  try {
    return _serialFromJsonValue(jsonDecode(raw));
  } on FormatException {
    return null;
  }
}

String? _serialFromJsonValue(Object? value) {
  if (value is Map) {
    for (final entry in value.entries) {
      final key = entry.key.toString().replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
      if (_serialKeys.contains(key.toLowerCase())) {
        final serial = normalizeSensorSerial(entry.value?.toString());
        if (serial != null) return serial;
      }
    }

    for (final entry in value.entries) {
      final nested = _serialFromJsonValue(entry.value);
      if (nested != null) return nested;
    }
  }

  if (value is List) {
    for (final item in value) {
      final nested = _serialFromJsonValue(item);
      if (nested != null) return nested;
    }
  }

  return null;
}

String? _serialFromQuery(Uri uri) {
  for (final entry in uri.queryParametersAll.entries) {
    final key = entry.key.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (!_serialKeys.contains(key.toLowerCase())) continue;

    for (final value in entry.value) {
      final serial = normalizeSensorSerial(value);
      if (serial != null) return serial;
    }
  }

  return null;
}

String? _serialFromPath(Uri uri) {
  for (final segment in uri.pathSegments.reversed) {
    final decoded = Uri.decodeComponent(segment).trim();
    if (_ignoredPathTokens.contains(decoded.toLowerCase())) continue;

    final serial = normalizeSensorSerial(decoded);
    if (serial != null) return serial;
  }

  return null;
}

String? _serialFromLabeledText(String raw) {
  final match = RegExp(
    r'\b(?:sn|serial(?:\s*number)?|sensor(?:\s*sn|\s*id|\s*serial)?|device(?:\s*sn|\s*id|\s*serial)?|code)\b\s*[:=#-]?\s*([A-Za-z0-9_-]{4,64})\b',
    caseSensitive: false,
  ).firstMatch(raw);

  return normalizeSensorSerial(match?.group(1));
}

String? _serialFromGs1(String raw) {
  final explicit = _serialFromParenthesizedGs1(raw);
  if (explicit != null) return explicit;

  final compact = raw
      .replaceAll(RegExp(r'^\][A-Za-z0-9]{2}'), '')
      .replaceAll(String.fromCharCode(29), '')
      .replaceAll(RegExp(r'[\s()]+'), '');

  final gtinMatch = RegExp(r'01(\d{14})').firstMatch(compact);
  if (gtinMatch == null) return null;

  var cursor = gtinMatch.end;
  while (cursor + 2 <= compact.length) {
    final ai = compact.substring(cursor, cursor + 2);
    if (ai == '11' || ai == '17') {
      cursor += 8;
      continue;
    }
    if (ai == '21') {
      final serial = normalizeSensorSerial(compact.substring(cursor + 2));
      return _composeGtinSerial(gtinMatch.group(1), serial);
    }
    break;
  }

  return null;
}

String? _serialFromParenthesizedGs1(String raw) {
  final gtin = RegExp(r'\(01\)\s*(\d{14})').firstMatch(raw)?.group(1);
  final serial = RegExp(
    r'\(21\)\s*([A-Za-z0-9_-]{4,64})',
    caseSensitive: false,
  ).firstMatch(raw)?.group(1);

  return _composeGtinSerial(gtin, normalizeSensorSerial(serial));
}

String? _composeGtinSerial(String? gtin, String? serial) {
  if (serial == null) return null;

  final prefix = gtin == null ? null : _modelPrefixByGtin[gtin];
  if (prefix == null || serial.startsWith(prefix)) return serial;

  return normalizeSensorSerial('$prefix$serial');
}

bool _isSerialCandidate(String value) {
  if (value.length < 4 || value.length > 64) return false;
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(value)) {
    return false;
  }

  final lower = value.toLowerCase();
  if (_ignoredPathTokens.contains(lower)) return false;

  return true;
}
