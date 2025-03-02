import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AutoCompleteTextField extends StatefulWidget {
  /// {@macro TextField.controller}
  final TextEditingController? controller;

  /// The list of possible text values to match.
  final List<String> textValues;

  /// {@macro flutter.widgets.editableText.keyboardType}
  final TextInputType? keyboardType;

  /// {@macro flutter.widgets.editableText.inputFormatters}
  final List<TextInputFormatter>? inputFormatters;

  /// {@macro flutter.widgets.editableText.textCapitalization}
  final TextCapitalization textCapitalization;

  /// The decoration to show around the text field.
  final InputDecoration? decoration;

  /// {@macro flutter.widgets.editableText.autofocus}
  final bool autofocus;

  /// {@macro flutter.widgets.editableText.obscureText}
  final bool obscureText;

  /// {@macro flutter.widgets.editableText.autocorrect}
  final bool autocorrect;

  /// {@macro flutter.widgets.editableText.onChanged}
  final ValueChanged<String>? onChanged;

  /// {@macro flutter.widgets.editableText.onSubmitted}
  final ValueChanged<String>? onSubmitted;

  /// Similar to the Material TextField, except that it provides a list of text
  /// selections to be used to match what the user has typed.
  const AutoCompleteTextField({
    super.key,
    required this.textValues,
    this.controller,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.textCapitalization = TextCapitalization.none,
    this.decoration = const InputDecoration(),
    this.obscureText = false,
    this.autofocus = false,
    this.autocorrect = true,
  });

  @override
  State<AutoCompleteTextField> createState() => _AutoCompleteTextFieldState();
}

class _AutoCompleteTextFieldState extends State<AutoCompleteTextField> {
  @override
  Widget build(BuildContext context) {
    TextEditingController ctrl = widget.controller ?? TextEditingController();
    return RawAutocomplete<String>(
      focusNode: FocusNode(),
      textEditingController: ctrl,
      optionsBuilder: (textEditingValue) => widget.textValues
          .where((String option) => option.contains(textEditingValue.text)),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) =>
              TextField(
        autocorrect: widget.autocorrect,
        controller: textEditingController,
        focusNode: focusNode,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        decoration: widget.decoration,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 4,
          child: SizedBox(
            // Dynamically determine the height based on
            // the number of items to display.
            height: min(options.length, 3) * 65.0,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: options.length,
              itemBuilder: (BuildContext context, int index) {
                final String option = options.elementAt(index);
                return GestureDetector(
                  onTap: () {
                    onSelected(option);
                    // Due to the way onSelected works, we need to call the
                    // widget's onChanged method manually.  It does not get
                    // called by onSelected.
                    if (widget.onChanged != null) {
                      widget.onChanged!(option);
                    }
                  },
                  child: ListTile(title: Text(option)),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
