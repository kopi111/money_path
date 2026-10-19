import 'package:flutter/material.dart';

import '../../domain/goals/goal_standing.dart';

/// Cover colours avoid green, amber and red, which belong to goal status.
///
/// The Exercise Book world: feint-ruled paper, a red margin rule, ballpoint
/// ink, and the solid card covers Jamaican exercise books come in.
@immutable
class BookPalette extends ThemeExtension<BookPalette> {
  const BookPalette({
    required this.paper,
    required this.rule,
    required this.margin,
    required this.ink,
    required this.inkSoft,
    required this.labelPlate,
    required this.onLabelPlate,
    required this.covers,
    required this.onCover,
    required this.ahead,
    required this.slipping,
    required this.behind,
    required this.onStatus,
  });

  final Color paper;
  final Color rule;
  final Color margin;
  final Color ink;
  final Color inkSoft;
  final Color labelPlate;
  final Color onLabelPlate;
  final List<Color> covers;
  final Color onCover;
  final Color ahead;
  final Color slipping;
  final Color behind;
  final Color onStatus;

  static const light = BookPalette(
    paper: Color(0xFFFBFCFA),
    rule: Color(0xFFC7D6EB),
    margin: Color(0xFFD9483B),
    ink: Color(0xFF15245C),
    inkSoft: Color(0xFF475377),
    labelPlate: Color(0xFFFFFFFF),
    onLabelPlate: Color(0xFF15245C),
    covers: [
      Color(0xFF1D4FB5),
      Color(0xFF6A3AA8),
      Color(0xFF0F6E7A),
      Color(0xFF8A2C6B),
      Color(0xFF3B4A9C),
      Color(0xFF455A64),
    ],
    onCover: Color(0xFFFFFFFF),
    ahead: Color(0xFF17703F),
    slipping: Color(0xFF8F5B00),
    behind: Color(0xFFB3261E),
    onStatus: Color(0xFFFFFFFF),
  );

  static const dark = BookPalette(
    paper: Color(0xFF10172A),
    rule: Color(0xFF34436A),
    margin: Color(0xFFE0685C),
    ink: Color(0xFFE9EDF8),
    inkSoft: Color(0xFFAEB7D0),
    // The night book's plate stays dark: its status colours are tuned light
    // for a dark ground and would lose contrast on white.
    labelPlate: Color(0xFF1A2440),
    onLabelPlate: Color(0xFFE9EDF8),
    covers: [
      Color(0xFF2F63D0),
      Color(0xFF7D4DBD),
      Color(0xFF13717F),
      Color(0xFF9A3A7C),
      Color(0xFF4A5BB5),
      Color(0xFF52666F),
    ],
    onCover: Color(0xFFFFFFFF),
    ahead: Color(0xFF6FD69C),
    slipping: Color(0xFFF2C25B),
    behind: Color(0xFFFF8F80),
    onStatus: Color(0xFF10172A),
  );

  /// A stable cover colour per goal, the same on every launch.
  Color coverFor(String goalId) => covers[goalId.codeUnits.fold(0, (sum, unit) => sum + unit) % covers.length];

  Color statusColour(StatusLight light) => switch (light) {
        StatusLight.green => ahead,
        StatusLight.amber => slipping,
        StatusLight.red => behind,
        StatusLight.neutral => inkSoft,
      };

  @override
  BookPalette copyWith({Color? paper, Color? ink}) => BookPalette(
        paper: paper ?? this.paper,
        rule: rule,
        margin: margin,
        ink: ink ?? this.ink,
        inkSoft: inkSoft,
        labelPlate: labelPlate,
        onLabelPlate: onLabelPlate,
        covers: covers,
        onCover: onCover,
        ahead: ahead,
        slipping: slipping,
        behind: behind,
        onStatus: onStatus,
      );

  @override
  BookPalette lerp(BookPalette? other, double t) => t < 0.5 || other == null ? this : other;
}

extension BookPaletteLookup on BuildContext {
  BookPalette get book => Theme.of(this).extension<BookPalette>()!;
}
