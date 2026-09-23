/// @docImport 'dental_teeth_selector.dart';
library;

/// Dental tooth numbering systems supported by [DentalTeethSelector].
enum TeethNumberingSystem {
  /// Universal Numbering System (ADA): `"1"` … `"32"`.
  ///
  /// Upper right third molar is `1`, counting clockwise to lower right
  /// third molar `32`.
  universal,

  /// FDI World Dental Federation notation (ISO 3950 / European).
  ///
  /// Two-digit ids: quadrant (1–4) + tooth (1–8), e.g. `"11"`, `"18"`,
  /// `"21"`, `"28"`, `"31"`, `"38"`, `"41"`, `"48"`.
  european,
}

/// Universal (`"1"`…`"32"`) → FDI European (`"11"`…`"48"`) lookup.
const Map<String, String> kUniversalToEuropean = {
  '1': '18',
  '2': '17',
  '3': '16',
  '4': '15',
  '5': '14',
  '6': '13',
  '7': '12',
  '8': '11',
  '9': '21',
  '10': '22',
  '11': '23',
  '12': '24',
  '13': '25',
  '14': '26',
  '15': '27',
  '16': '28',
  '17': '38',
  '18': '37',
  '19': '36',
  '20': '35',
  '21': '34',
  '22': '33',
  '23': '32',
  '24': '31',
  '25': '41',
  '26': '42',
  '27': '43',
  '28': '44',
  '29': '45',
  '30': '46',
  '31': '47',
  '32': '48',
};

/// FDI European → Universal lookup.
final Map<String, String> kEuropeanToUniversal = {
  for (final e in kUniversalToEuropean.entries) e.value: e.key,
};

/// Converts a tooth id from [from] to [to].
///
/// Returns [id] unchanged when systems match. Throws [ArgumentError] if [id]
/// is not valid for [from].
String convertToothId(
  String id, {
  required TeethNumberingSystem from,
  required TeethNumberingSystem to,
}) {
  if (from == to) {
    return id;
  }
  if (from == TeethNumberingSystem.universal &&
      to == TeethNumberingSystem.european) {
    final mapped = kUniversalToEuropean[id];
    if (mapped == null) {
      throw ArgumentError.value(id, 'id', 'Not a valid Universal tooth id');
    }
    return mapped;
  }
  final mapped = kEuropeanToUniversal[id];
  if (mapped == null) {
    throw ArgumentError.value(id, 'id', 'Not a valid European (FDI) tooth id');
  }
  return mapped;
}

/// Converts a list of tooth ids from [from] to [to].
List<String> convertToothIds(
  Iterable<String> ids, {
  required TeethNumberingSystem from,
  required TeethNumberingSystem to,
}) {
  return [
    for (final id in ids) convertToothId(id, from: from, to: to),
  ];
}
