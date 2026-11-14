import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model.dart';

/// The group and the release time. Saved in the app's private storage on this phone.
class AppState extends ChangeNotifier {
  final List<Devotee> devotees = [];
  DateTime? releaseAt;
  bool loaded = false;

  static const _k = 'ttd_helper_v1';

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString(_k);
      if (raw != null) {
        final j = jsonDecode(raw) as Map<String, dynamic>;
        devotees.addAll([
          for (final d in j['devotees'] as List)
            Devotee.fromJson(d as Map<String, dynamic>),
        ]);
        final r = j['releaseAt'] as String?;
        releaseAt = r == null ? null : DateTime.parse(r);
      }
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        _k,
        jsonEncode({
          'devotees': [for (final d in devotees) d.toJson()],
          'releaseAt': releaseAt?.toIso8601String(),
        }),
      );
    } catch (_) {}
  }

  void upsert(Devotee d) {
    final i = devotees.indexWhere((x) => x.id == d.id);
    if (i >= 0) {
      devotees[i] = d;
    } else {
      devotees.add(d);
    }
    _save();
  }

  void remove(Devotee d) {
    devotees.removeWhere((x) => x.id == d.id);
    _save();
  }

  /// [to] is the index after removal, as ReorderableListView.onReorderItem gives it.
  void reorder(int from, int to) {
    final d = devotees.removeAt(from);
    devotees.insert(to, d);
    _save();
  }

  void setRelease(DateTime? at) {
    releaseAt = at;
    _save();
  }
}
