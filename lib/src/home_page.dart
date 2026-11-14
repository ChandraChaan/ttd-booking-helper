import 'dart:async';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';

import 'booking_page.dart';
import 'devotee_sheet.dart';
import 'look.dart';
import 'model.dart';
import 'state.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

String _when(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '${t.day} ${_months[t.month - 1]}, $h:${t.minute.toString().padLeft(2, '0')} ${t.hour < 12 ? 'am' : 'pm'}';
}

/// Opens the phone's clock app with an alarm a few minutes before release.
/// Uses the standard SET_ALARM intent, so the app needs no alarm permission
/// of its own and the alarm lives in your usual clock app.
Future<bool> setPhoneAlarm(DateTime release, {int minutesBefore = 5}) async {
  final at = release.subtract(Duration(minutes: minutesBefore));
  try {
    await AndroidIntent(
      action: 'android.intent.action.SET_ALARM',
      arguments: {
        'android.intent.extra.alarm.HOUR': at.hour,
        'android.intent.extra.alarm.MINUTES': at.minute,
        'android.intent.extra.alarm.MESSAGE':
            'TTD quota opens at ${_when(release)}',
      },
    ).launch();
    return true;
  } catch (_) {
    return false;
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.state, this.clock});

  final AppState state;
  final DateTime Function()? clock;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? tick;
  AppState get s => widget.state;
  DateTime now() => (widget.clock ?? DateTime.now)();

  @override
  void initState() {
    super.initState();
    tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && s.releaseAt != null) setState(() {});
    });
  }

  @override
  void dispose() {
    tick?.cancel();
    super.dispose();
  }

  Future<void> _pickRelease() async {
    final base =
        s.releaseAt ?? DateTime(now().year, now().month, now().day, 10);
    final d = await showDatePicker(
      context: context,
      initialDate: base.isBefore(now()) ? now() : base,
      firstDate: DateTime(now().year, now().month, now().day),
      lastDate: now().add(const Duration(days: 120)),
      helpText: 'Release date from TTD announcement',
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: 'Release time',
    );
    if (t == null) return;
    s.setRelease(DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        final release = s.releaseAt;
        final problems = s.devotees.where((d) => d.idProblem != null).length;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 72,
            titleSpacing: 20,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TTD BOOKING HELPER',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    color: l.gold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text('Your group, ready for quota day'),
              ],
            ),
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1.2),
              child: GoldRule(),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                _ReleaseCard(
                  release: release,
                  now: now(),
                  onSet: _pickRelease,
                  onAlarm: release == null
                      ? null
                      : () async {
                          final ok = await setPhoneAlarm(release);
                          if (!ok && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'No clock app answered. Set an alarm by hand.',
                                ),
                              ),
                            );
                          }
                        },
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    Text('DEVOTEES', style: l.label()),
                    const SizedBox(width: 8),
                    Text(
                      '${s.devotees.length}',
                      style: TextStyle(
                        color: l.muted,
                        fontFeatures: Look.figures,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () async {
                        final d = await editDevotee(context);
                        if (d != null) s.upsert(d);
                      },
                      icon: const Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 18,
                      ),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (s.loaded && s.devotees.isEmpty)
                  Text(
                    'Add everyone going: name exactly as on the photo ID, age, gender and ID number. '
                    'On release day you will not have time to look these up.',
                    style: TextStyle(color: l.muted, height: 1.4),
                  ),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  onReorderItem: s.reorder,
                  children: [
                    for (var i = 0; i < s.devotees.length; i++)
                      _DevoteeTile(
                        key: ValueKey(s.devotees[i].id),
                        index: i,
                        d: s.devotees[i],
                        onTap: () async {
                          final d = await editDevotee(
                            context,
                            existing: s.devotees[i],
                          );
                          if (d != null) s.upsert(d);
                        },
                        onDelete: () => s.remove(s.devotees[i]),
                      ),
                  ],
                ),
                if (problems > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '$problems devotee${problems == 1 ? ' needs' : 's need'} a fix before release day.',
                      style: TextStyle(
                        color: l.warn,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                Text(
                  'You log in, type the OTP and captcha, choose the slot and pay yourself. '
                  'This app only types your group\'s details when you tap. Details stay on this phone.',
                  style: TextStyle(color: l.muted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Open TTD booking site'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => BookingPage(devotees: List.of(s.devotees)),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReleaseCard extends StatelessWidget {
  const _ReleaseCard({
    required this.release,
    required this.now,
    required this.onSet,
    required this.onAlarm,
  });

  final DateTime? release;
  final DateTime now;
  final VoidCallback onSet;
  final VoidCallback? onAlarm;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final r = release;
    final open = r != null && !r.isAfter(now);
    return Container(
      decoration: BoxDecoration(
        color: l.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: l.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: l.line, style: BorderStyle.solid),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r == null
                      ? 'QUOTA RELEASE'
                      : 'QUOTA OPENS ${_when(r).toUpperCase()}',
                  style: l.label(),
                ),
                const SizedBox(height: 6),
                Text(
                  r == null ? 'Not set' : countdown(now, r),
                  style: TextStyle(
                    fontSize: r == null ? 22 : 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: open ? l.maroon : (r == null ? l.muted : l.ink),
                    fontFeatures: Look.figures,
                  ),
                ),
                if (r == null)
                  Text(
                    'TTD announces each month\'s release date and time. Enter it here to get a countdown.',
                    style: TextStyle(
                      color: l.muted,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onSet,
                  icon: const Icon(Icons.event_outlined, size: 18),
                  label: Text(r == null ? 'Set release time' : 'Change'),
                ),
              ),
              Container(width: 1, height: 28, color: l.line),
              Expanded(
                child: TextButton.icon(
                  onPressed: onAlarm,
                  icon: const Icon(Icons.alarm_add_outlined, size: 18),
                  label: Text(
                    r == null
                        ? 'Phone alarm'
                        : 'Alarm at ${_clock(r.subtract(const Duration(minutes: 5)))}',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DevoteeTile extends StatelessWidget {
  const _DevoteeTile({
    super.key,
    required this.index,
    required this.d,
    required this.onTap,
    required this.onDelete,
  });

  final int index;
  final Devotee d;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final problem = d.idProblem;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: l.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: problem != null ? l.warn : l.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: l.gold, width: 1.4),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: l.gold,
                      fontFeatures: Look.figures,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        problem ??
                            '${d.age} · ${d.gender.label} · ${d.idType} ${d.maskedId}',
                        style: TextStyle(
                          color: problem != null ? l.warn : l.muted,
                          fontSize: 13,
                          fontFeatures: Look.figures,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_indicator, color: l.muted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
