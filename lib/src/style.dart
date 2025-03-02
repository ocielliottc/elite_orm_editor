import 'package:flutter/material.dart';

/// The base style for all editor/list screens.  Everything in this class can be
/// overridden to adjust the style to your own application.
class EliteORMEditorStyle {
  /// The size of icons used on the bottom app bar.
  double get iconSize => 40;

  /// Radius of the corner of borders.
  double get cornerRadius => 4;

  /// The border radius of containers and cards.
  BorderRadius get borderRadius =>
      BorderRadius.all(Radius.circular(cornerRadius));

  /// The padding for the bottom app bar.
  EdgeInsets get bottomBarPadding => EdgeInsets.zero;

  /// The box decoration for the bottom app bar.
  BoxDecoration bottomBarDecoration(context) => BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.secondary,
            width: 0.3,
          ),
        ),
      );

  /// The padding for the main column containing the editing widgets.
  EdgeInsets get columnPadding =>
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  /// The style for each group title.
  TextStyle get titleText =>
      const TextStyle(fontSize: 22, fontWeight: FontWeight.bold);

  /// The padding for input widgets.
  EdgeInsets get textPadding =>
      const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 8);

  /// The padding between input widgets and their labels.
  EdgeInsets get labelPadding => const EdgeInsets.only(left: 8);

  /// Padding inside containers between the outer edge and the inner widget.
  EdgeInsets get innerPadding => const EdgeInsets.all(3);

  /// The decoration for input widgets, specifically TextField widgets.
  InputDecoration hintDecoration([String? hint]) =>
      InputDecoration(border: const OutlineInputBorder(), hintText: hint);

  /// Container box decoration.
  BoxDecoration containerOutline(context) => BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: borderRadius,
      );

  /// The title text style for Card widgets.
  TextStyle get cardTitleText =>
      const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w500);

  /// The padding for the duration labels.
  EdgeInsets get durationLabelPadding =>
      const EdgeInsets.symmetric(vertical: 4);

  /// The text style for the duration labels.
  TextStyle get durationLabelText =>
      const TextStyle(fontWeight: FontWeight.bold);

  /// The shape of Card widgets.
  RoundedRectangleBorder cardShape(context) => RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.primaryContainer),
        borderRadius: borderRadius,
      );

  /// The amount of padding on the trashcan icon underneath the dismissible
  /// list card.
  double get listTrashcanPadding => 10;

  /// The flex amount used for text inputs with a label and/or obscuration icon.
  int get textInputFlex => 11;

  /// The style of the duration number picker and separator text.
  TextStyle? durationNumberStyle(context) => Theme.of(context)
      .textTheme
      .headlineSmall
      ?.copyWith(color: Theme.of(context).colorScheme.secondary);
}
