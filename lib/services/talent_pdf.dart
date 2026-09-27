import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:talent_foot_connect/models/feed_post.dart';
import 'package:talent_foot_connect/models/talent_public_profile.dart';

const _ink = PdfColor.fromInt(0xFF121414);
const _muted = PdfColor.fromInt(0xFF5C6560);
const _orange = PdfColor.fromInt(0xFFFE6B00);
const _mint = PdfColor.fromInt(0xFF1B6B38);
const _card = PdfColor.fromInt(0xFFF3F6F1);
const _line = PdfColor.fromInt(0xFFE3E8E0);

class _PdfFonts {
  const _PdfFonts({
    required this.base,
    required this.semi,
    required this.bold,
    required this.extra,
    required this.mono,
  });

  final pw.Font base;
  final pw.Font semi;
  final pw.Font bold;
  final pw.Font extra;
  final pw.Font mono;
}

String talentPdfFileName(String name) {
  const accents = {
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'ï': 'i',
    'î': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  var slug = name.toLowerCase();
  for (final entry in accents.entries) {
    slug = slug.replaceAll(entry.key, entry.value);
  }
  slug = slug
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return 'fiche-${slug.isEmpty ? 'joueur' : slug}.pdf';
}

Future<Uint8List> buildTalentProfilePdf(TalentPublicProfile profile) async {
  final fonts = await _loadFonts();
  final photo = await _loadPhoto(profile.photoUrl);
  final logo = await _loadLogo();
  final generatedAt = _formatDate(DateTime.now());

  final doc = pw.Document(
    title: 'Fiche ${profile.name}',
    author: 'TalentFoot Connect',
  );

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 32),
      theme: pw.ThemeData.withFont(base: fonts.base, bold: fonts.bold),
      footer: (context) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 10),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'TalentFoot Connect · $generatedAt',
              style: pw.TextStyle(font: fonts.base, fontSize: 8, color: _muted),
            ),
            pw.Text(
              '${context.pageNumber}/${context.pagesCount}',
              style: pw.TextStyle(font: fonts.mono, fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (context) => [
        _header(profile, fonts, logo),
        pw.SizedBox(height: 18),
        _identity(profile, fonts, photo),
        pw.SizedBox(height: 16),
        _stats(profile, fonts),
        if (_text(profile.description) != null) ...[
          pw.SizedBox(height: 16),
          _section('Présentation', fonts),
          pw.SizedBox(height: 8),
          pw.Text(
            _text(profile.description)!,
            style: pw.TextStyle(font: fonts.base, fontSize: 11, height: 1.4, color: _ink),
          ),
        ],
        pw.SizedBox(height: 16),
        _section('Historique clubs', fonts),
        pw.SizedBox(height: 8),
        _clubs(profile, fonts),
        pw.SizedBox(height: 16),
        _section('Analyse de performance', fonts),
        pw.SizedBox(height: 8),
        _performance(profile, fonts),
        if (profile.media.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _section('Highlights', fonts),
          pw.SizedBox(height: 8),
          _highlights(profile, fonts),
        ],
      ],
    ),
  );

  return doc.save();
}

Future<_PdfFonts> _loadFonts() async {
  final regular = pw.Font.helvetica();
  final bold = pw.Font.helveticaBold();
  final loaded = await Future.wait([
    _assetFont('Inter-Regular.ttf', regular),
    _assetFont('Montserrat-SemiBold.ttf', bold),
    _assetFont('Montserrat-Bold.ttf', bold),
    _assetFont('Montserrat-ExtraBold.ttf', bold),
    _assetFont('JetBrainsMono-Bold.ttf', bold),
  ]);
  return _PdfFonts(
    base: loaded[0],
    semi: loaded[1],
    bold: loaded[2],
    extra: loaded[3],
    mono: loaded[4],
  );
}

Future<pw.Font> _assetFont(String fileName, pw.Font fallback) async {
  try {
    final data = await rootBundle.load('assets/fonts/$fileName');
    return pw.Font.ttf(data);
  } catch (_) {
    return fallback;
  }
}

Future<pw.ImageProvider?> _loadPhoto(String? url) async {
  if (url == null || url.trim().isEmpty) return null;
  try {
    return await networkImage(url);
  } catch (_) {
    return null;
  }
}

Future<pw.MemoryImage?> _loadLogo() async {
  try {
    final data = await rootBundle.load('assets/images/logo.jpeg');
    return pw.MemoryImage(data.buffer.asUint8List());
  } catch (_) {
    return null;
  }
}

pw.Widget _header(
  TalentPublicProfile profile,
  _PdfFonts fonts,
  pw.MemoryImage? logo,
) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: pw.BoxDecoration(
      color: _ink,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Row(
      children: [
        if (logo != null) ...[
          pw.Container(
            width: 36,
            height: 36,
            child: pw.ClipRRect(
              horizontalRadius: 6,
              verticalRadius: 6,
              child: pw.Image(logo, fit: pw.BoxFit.cover),
            ),
          ),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'TALENTFOOTPRO',
                style: pw.TextStyle(
                  font: fonts.extra,
                  fontSize: 16,
                  color: PdfColors.white,
                  letterSpacing: 0.4,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Fiche joueur',
                style: pw.TextStyle(
                  font: fonts.base,
                  fontSize: 10,
                  color: const PdfColor.fromInt(0xFFC2C9BB),
                ),
              ),
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(
            color: _orange,
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Text(
            profile.prospectLabel,
            style: pw.TextStyle(
              font: fonts.mono,
              fontSize: 9,
              color: const PdfColor.fromInt(0xFF572000),
            ),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _identity(
  TalentPublicProfile profile,
  _PdfFonts fonts,
  pw.ImageProvider? photo,
) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _portrait(photo, profile.name, fonts),
      pw.SizedBox(width: 16),
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              profile.name,
              style: pw.TextStyle(font: fonts.extra, fontSize: 22, color: _ink),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              [
                profile.position,
                profile.city,
                if (profile.verified) 'Profil vérifié',
              ].join('  ·  '),
              style: pw.TextStyle(font: fonts.semi, fontSize: 11, color: _muted),
            ),
          ],
        ),
      ),
    ],
  );
}

pw.Widget _portrait(pw.ImageProvider? photo, String name, _PdfFonts fonts) {
  return pw.Container(
    width: 92,
    height: 112,
    decoration: pw.BoxDecoration(
      color: _card,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _line),
    ),
    child: pw.ClipRRect(
      horizontalRadius: 8,
      verticalRadius: 8,
      child: photo == null
          ? pw.Center(
              child: pw.Text(
                _initials(name),
                style: pw.TextStyle(font: fonts.bold, fontSize: 22, color: _mint),
              ),
            )
          : pw.Image(photo, fit: pw.BoxFit.cover),
    ),
  );
}

pw.Widget _stats(TalentPublicProfile profile, _PdfFonts fonts) {
  return pw.Column(
    children: [
      pw.Row(
        children: [
          pw.Expanded(child: _stat('ÂGE', '${profile.age} ans', fonts)),
          pw.SizedBox(width: 8),
          pw.Expanded(child: _stat('TAILLE', profile.height, fonts)),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Row(
        children: [
          pw.Expanded(child: _stat('POIDS', profile.weight, fonts)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: _stat('ABONNÉS', '${profile.followersCount}', fonts),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _stat(String label, String value, _PdfFonts fonts) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: _card,
      borderRadius: pw.BorderRadius.circular(6),
      border: pw.Border.all(color: _line),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            font: fonts.mono,
            fontSize: 8,
            color: _muted,
            letterSpacing: 0.6,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          value,
          style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: _ink),
        ),
      ],
    ),
  );
}

pw.Widget _section(String title, _PdfFonts fonts) {
  return pw.Row(
    children: [
      pw.Container(width: 3, height: 14, color: _mint),
      pw.SizedBox(width: 8),
      pw.Text(
        title,
        style: pw.TextStyle(font: fonts.bold, fontSize: 13, color: _ink),
      ),
    ],
  );
}

pw.Widget _clubs(TalentPublicProfile profile, _PdfFonts fonts) {
  if (profile.clubs.isEmpty) {
    return pw.Text(
      'Aucun club renseigné.',
      style: pw.TextStyle(font: fonts.base, fontSize: 11, color: _muted),
    );
  }

  return pw.Column(
    children: [
      for (var i = 0; i < profile.clubs.length; i++) ...[
        if (i > 0) pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  profile.clubs[i].club,
                  style: pw.TextStyle(font: fonts.semi, fontSize: 11, color: _ink),
                ),
              ),
              pw.Text(
                profile.clubs[i].period,
                style: pw.TextStyle(font: fonts.mono, fontSize: 9, color: _muted),
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

pw.Widget _performance(TalentPublicProfile profile, _PdfFonts fonts) {
  if (!profile.performanceUnlocked) {
    return pw.Text(
      'Analyse de performance réservée à l\'abonnement PRO.',
      style: pw.TextStyle(font: fonts.base, fontSize: 11, color: _muted),
    );
  }
  if (profile.bars.isEmpty) {
    return pw.Text(
      'Le joueur n\'a pas encore renseigné son analyse.',
      style: pw.TextStyle(font: fonts.base, fontSize: 11, color: _muted),
    );
  }

  return pw.Column(
    children: [
      for (final bar in profile.bars) ...[
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Text(
                bar.label,
                style: pw.TextStyle(font: fonts.mono, fontSize: 9, color: _muted),
              ),
            ),
            pw.Text(
              '${bar.value}/10',
              style: pw.TextStyle(font: fonts.bold, fontSize: 11, color: _mint),
            ),
          ],
        ),
        pw.SizedBox(height: 4),
        _scoreBar(bar.value),
        pw.SizedBox(height: 10),
      ],
    ],
  );
}

pw.Widget _scoreBar(int value) {
  final score = value.clamp(0, 10);
  return pw.Container(
    height: 6,
    decoration: pw.BoxDecoration(
      color: _line,
      borderRadius: pw.BorderRadius.circular(4),
    ),
    child: pw.Row(
      children: [
        if (score > 0)
          pw.Expanded(
            flex: score,
            child: pw.Container(
              decoration: pw.BoxDecoration(
                color: _mint,
                borderRadius: pw.BorderRadius.circular(4),
              ),
            ),
          ),
        if (score < 10) pw.Spacer(flex: 10 - score),
      ],
    ),
  );
}

pw.Widget _highlights(TalentPublicProfile profile, _PdfFonts fonts) {
  final photos =
      profile.media.where((post) => post.mediaType == FeedMediaType.image).length;
  final videos = profile.media.length - photos;
  final captions = profile.media
      .map((post) => _text(post.caption))
      .whereType<String>()
      .take(8)
      .toList();
  final counts = [
    if (photos > 0) '$photos photo${photos > 1 ? 's' : ''}',
    if (videos > 0) '$videos vidéo${videos > 1 ? 's' : ''}',
  ].join(' · ');

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        counts,
        style: pw.TextStyle(font: fonts.semi, fontSize: 11, color: _ink),
      ),
      if (captions.isNotEmpty) ...[
        pw.SizedBox(height: 6),
        for (final caption in captions)
          pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 3),
            child: pw.Text(
              '- $caption',
              style: pw.TextStyle(font: fonts.base, fontSize: 10, color: _muted),
            ),
          ),
      ],
    ],
  );
}

String? _text(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase());
  final initials = parts.join();
  return initials.isEmpty ? '?' : initials;
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
