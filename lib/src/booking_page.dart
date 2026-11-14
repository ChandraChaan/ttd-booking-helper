import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'look.dart';
import 'model.dart';

/// The official TTD site in a browser, with your group in a tray below it.
/// Tap a box on the page, then tap a chip: that value is typed into the box.
class BookingPage extends StatefulWidget {
  const BookingPage({super.key, required this.devotees});
  final List<Devotee> devotees;

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  late final WebViewController web;
  String? fillJs;
  int who = 0;
  bool trayOpen = true;
  int progress = 0;
  String host = ttdPortal.host;

  @override
  void initState() {
    super.initState();
    web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => setState(() => progress = p),
          onPageFinished: (_) => _inject(),
          onUrlChange: (c) {
            final u = Uri.tryParse(c.url ?? '');
            if (u != null) setState(() => host = u.host);
            _inject();
          },
          onNavigationRequest: (req) async {
            final uri = intentToUri(req.url) ?? Uri.tryParse(req.url);
            if (uri != null && opensOutside(uri)) {
              // UPI, phone, mail and app-store links go to the right app on the phone.
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              ).catchError((_) => false);
              if (!ok && mounted) {
                _say('No app on this phone can open that link.');
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(ttdPortal);
    rootBundle.loadString('assets/fill.js').then((s) {
      fillJs = s;
      _inject();
    });
  }

  Future<void> _inject() async {
    final js = fillJs;
    if (js == null) return;
    try {
      await web.runJavaScript(js);
    } catch (_) {}
  }

  void _say(String m) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(m), duration: const Duration(seconds: 2)),
      );
  }

  /// The page returns a JSON string on Android and a plain value elsewhere.
  Object? _result(Object raw) {
    if (raw is String) {
      try {
        return jsonDecode(raw);
      } catch (_) {
        return raw;
      }
    }
    return raw;
  }

  Future<void> _insert(String value) async {
    await _inject();
    try {
      final r = _result(
        await web.runJavaScriptReturningResult(
          'window.TtdHelper.insert(${jsonEncode(value)})',
        ),
      );
      if (r != 'ok') _say('$r');
      HapticFeedback.selectionClick();
    } catch (_) {
      _say('The page is still loading.');
    }
  }

  Future<void> _fillAll() async {
    await _inject();
    final rows = [
      for (final d in widget.devotees)
        {for (final f in DevoteeField.values) f.name: d.valueOf(f)},
    ];
    try {
      final r = _result(
        await web.runJavaScriptReturningResult(
          'window.TtdHelper.fillRows(${jsonEncode(rows)})',
        ),
      );
      final n = r is num ? r.toInt() : int.tryParse('$r') ?? 0;
      _say(
        n == 0
            ? 'No devotee boxes found on this step. Use the chips instead.'
            : 'Filled $n boxes. Check every row against the IDs before you continue.',
      );
    } catch (_) {
      _say('The page is still loading.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = Look.of(context);
    final group = widget.devotees;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await web.canGoBack()) {
          await web.goBack();
        } else if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: l.gold),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  host,
                  style: const TextStyle(fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Reload',
              onPressed: () => web.reload(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: progress < 100
                ? LinearProgressIndicator(
                    value: progress / 100,
                    minHeight: 2,
                    color: l.gold,
                    backgroundColor: Colors.transparent,
                  )
                : const GoldRule(),
          ),
        ),
        body: Column(
          children: [
            Expanded(child: WebViewWidget(controller: web)),
            if (group.isNotEmpty) _tray(l, group),
          ],
        ),
      ),
    );
  }

  Widget _tray(Look l, List<Devotee> group) {
    final d = group[who.clamp(0, group.length - 1)];
    return Material(
      color: l.paper,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: l.gold, width: 1.2)),
          ),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text('TAP A BOX, THEN A CHIP', style: l.label()),
                  const Spacer(),
                  TextButton(
                    onPressed: _fillAll,
                    child: const Text('Fill all rows'),
                  ),
                  IconButton(
                    tooltip: trayOpen ? 'Hide' : 'Show',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() => trayOpen = !trayOpen),
                    icon: Icon(
                      trayOpen ? Icons.expand_more : Icons.expand_less,
                    ),
                  ),
                ],
              ),
              if (trayOpen) ...[
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (var i = 0; i < group.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(
                              '${i + 1}. ${group[i].name.split(' ').first}',
                            ),
                            selected: i == who,
                            onSelected: (_) => setState(() => who = i),
                            selectedColor: l.maroon,
                            labelStyle: TextStyle(
                              color: i == who ? l.onMaroon : l.ink,
                              fontWeight: FontWeight.w600,
                            ),
                            showCheckmark: false,
                            side: BorderSide(color: l.line),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final f in DevoteeField.values)
                      ActionChip(
                        avatar: Text(
                          f.label,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: l.muted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        label: Text(
                          f == DevoteeField.idNumber
                              ? d.maskedId
                              : d.valueOf(f),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: Look.figures,
                          ),
                        ),
                        onPressed: () => _insert(d.valueOf(f)),
                        backgroundColor: l.card,
                        side: BorderSide(color: l.line),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
