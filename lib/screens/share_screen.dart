import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../models/idiom.dart';

/// Vorschau einer Bild-Karte, die geteilt werden kann (z. B. in WhatsApp
/// oder als Instagram-Story).
class ShareScreen extends StatefulWidget {
  const ShareScreen({super.key, required this.idiom});

  final Idiom idiom;

  @override
  State<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends State<ShareScreen> {
  final _cardKey = GlobalKey();
  final _buttonKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      // iPad braucht eine Position für das Teilen-Menü.
      final box = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(png!.buffer.asUint8List(), mimeType: 'image/png'),
          ],
          fileNameOverrides: const ['redewendix.png'],
          text: '„${widget.idiom.text}“ – ${widget.idiom.meaning}',
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teilen')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FittedBox(
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: ShareCard(idiom: widget.idiom),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: _buttonKey,
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Bild teilen'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die Karte selbst: feste Größe (4:5) und feste Farben, unabhängig vom
/// Design und der Schriftgröße der App.
class ShareCard extends StatelessWidget {
  const ShareCard({super.key, required this.idiom});

  final Idiom idiom;

  static const size = Size(360, 450);
  static const _green = Color(0xFF2F6B5A);
  static const _cream = Color(0xFFFAF7EF);
  static const _mint = Color(0xFFCFE6DB);

  @override
  Widget build(BuildContext context) {
    // Längere Redewendungen etwas kleiner setzen.
    final len = idiom.text.length;
    final titleSize = len <= 28
        ? 34.0
        : len <= 45
        ? 28.0
        : 23.0;

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox.fromSize(
        size: size,
        // Material liefert den Standard-Textstil (sonst gelbe Unterstreichung).
        child: Material(
          color: _green,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                const Text(
                  '„',
                  style: TextStyle(
                    color: _mint,
                    fontSize: 72,
                    height: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  idiom.text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _cream,
                    fontSize: titleSize,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  idiom.meaning,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _mint,
                    fontSize: 18,
                    height: 1.35,
                  ),
                ),
                const Spacer(flex: 2),
                const Divider(color: _mint, height: 24, thickness: 0.5),
                const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: _mint, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Redewendix',
                      style: TextStyle(
                        color: _cream,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Redewendung des Tages',
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: _mint, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
