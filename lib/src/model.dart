/// The devotee group and the quota release time, kept on the phone only.
library;

/// The official TTD booking portal.
final Uri ttdPortal = Uri.parse(
  'https://ttdevasthanams.ap.gov.in/home/dashboard',
);

enum Gender {
  male('Male'),
  female('Female'),
  other('Transgender');

  const Gender(this.label);
  final String label;
}

/// Photo ID types pilgrims commonly carry. The portal decides which it accepts.
const idTypes = ['Aadhaar', 'Passport', 'Driving Licence', 'Voter ID', 'PAN'];

class Devotee {
  const Devotee({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.idType,
    required this.idNumber,
  });

  final String id;

  /// Exactly as printed on the photo ID.
  final String name;
  final int age;
  final Gender gender;
  final String idType;
  final String idNumber;

  /// "XXXX XXXX 1234" so the full number is not on screen in a queue.
  String get maskedId {
    final digits = idNumber.replaceAll(RegExp(r'\s'), '');
    if (digits.length <= 4) return digits;
    final tail = digits.substring(digits.length - 4);
    return '${'•' * 4} $tail';
  }

  /// Aadhaar is 12 digits. Others vary, so only Aadhaar is checked.
  String? get idProblem {
    final n = idNumber.replaceAll(RegExp(r'\s'), '');
    if (n.isEmpty) return 'ID number missing';
    if (idType == 'Aadhaar' && !RegExp(r'^[2-9]\d{11}$').hasMatch(n)) {
      return 'Aadhaar has 12 digits';
    }
    return null;
  }

  /// Value for one field, as it should be typed into the form.
  String valueOf(DevoteeField f) => switch (f) {
    DevoteeField.name => name,
    DevoteeField.age => '$age',
    DevoteeField.gender => gender.label,
    DevoteeField.idType => idType,
    DevoteeField.idNumber => idNumber.replaceAll(RegExp(r'\s'), ''),
  };

  Devotee copyWith({
    String? name,
    int? age,
    Gender? gender,
    String? idType,
    String? idNumber,
  }) => Devotee(
    id: id,
    name: name ?? this.name,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    idType: idType ?? this.idType,
    idNumber: idNumber ?? this.idNumber,
  );

  Map<String, Object> toJson() => {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender.name,
    'idType': idType,
    'idNumber': idNumber,
  };

  static Devotee fromJson(Map<String, dynamic> j) => Devotee(
    id: j['id'] as String,
    name: j['name'] as String,
    age: j['age'] as int,
    gender: Gender.values.byName(j['gender'] as String),
    idType: j['idType'] as String,
    idNumber: j['idNumber'] as String,
  );
}

enum DevoteeField {
  name('Name'),
  age('Age'),
  gender('Gender'),
  idType('ID type'),
  idNumber('ID number');

  const DevoteeField(this.label);
  final String label;
}

/// "2 d 04:15:09", "04:15:09", or "Open now" once the time has passed.
String countdown(DateTime now, DateTime at) {
  final d = at.difference(now);
  if (d.isNegative || d == Duration.zero) return 'Open now';
  final days = d.inDays;
  final h = (d.inHours % 24).toString().padLeft(2, '0');
  final m = (d.inMinutes % 60).toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return days > 0 ? '$days d $h:$m:$s' : '$h:$m:$s';
}

/// Payment pages open UPI apps with Android "intent://" links, which a
/// WebView cannot follow. This turns
/// intent://pay?pa=x@y&am=1#Intent;scheme=upi;package=com.phonepe.app;end
/// into upi://pay?pa=x@y&am=1 so the phone's UPI app opens.
Uri? intentToUri(String url) {
  if (!url.startsWith('intent://')) return null;
  final hash = url.indexOf('#Intent;');
  if (hash < 0) return null;
  final body = url.substring('intent://'.length, hash);
  final scheme = RegExp(
    r';scheme=([^;]+);',
  ).firstMatch(url.substring(hash))?.group(1);
  if (scheme == null) return null;
  return Uri.tryParse('$scheme://$body');
}

/// Links the WebView should hand to other apps (UPI, phone, mail, Play Store).
bool opensOutside(Uri uri) => !{
  'http',
  'https',
  'about',
  'data',
  'blob',
  'javascript',
}.contains(uri.scheme);
