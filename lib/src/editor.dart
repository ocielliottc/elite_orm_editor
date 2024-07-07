import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:elite_orm/elite_orm.dart';
import 'package:numberpicker/numberpicker.dart';

import 'style.dart';
import 'auto_complete_text_field.dart';

/// Allows the user to track modifications in the UI.
abstract class ModificationTracker {
  /// Boolean to keep track of whether or not changes have been made in this
  /// editor.
  bool modified = false;
}

/// A general database control object that guides the group translation in how
/// to create the UI widgets.
class DBMemberControl {
  bool _obscured = true;
  IconData _eye = Icons.remove_red_eye;
  final List<Function> _listeners = [];

  /// The storage object for modification.
  final Entity entity;

  /// The index into the data members of the Entity object.  In general, there
  /// is a DBMemberControl for each DBMember.
  final int index;

  /// If applicable, this is the TextEditingController associated with this
  /// DBMember.  Not all DBMembers will need a controller.
  final dynamic controller;

  /// This stores the text hint for TextFields when used.
  String? hint;

  /// A label is optional and will be displayed after a TextField, if available.
  String? label;

  /// Tells the TextField whether or not to obscure the text.
  bool obscure;

  /// Forces the value to be treated as an int if it is a double.
  bool asInt;

  /// Use a Checkbox (instead of a Switch) for boolean database members.
  bool checkbox;

  /// If true, make this member read-only.
  bool readOnly;

  /// A list of values to provide as completion to text entered into a
  /// TextField.
  List<String>? completeValues;

  /// A function to convert from the stored value to a display value.
  dynamic Function(dynamic v) toDisplay = (v) => v;

  /// A function to convert from the display value to a value suitable for
  /// storage in the database.
  dynamic Function(dynamic v) fromDisplay = (v) => v;

  /// Construct a general database member control object.
  ///
  /// The modification tracker will be your child class object that extends
  /// EliteORMEditorState.
  DBMemberControl({
    required ModificationTracker tracker,
    required this.entity,
    required this.index,
    this.controller,
    this.hint,
    this.obscure = false,
    this.asInt = false,
    this.checkbox = false,
    this.readOnly = false,
    this.label,
    this.completeValues,
  }) {
    setController(member.value);
    hint ??= splitWords(member.key);
    addListener(() => tracker.modified = true);
  }

  /// Return the database member associated with this control object.
  DBMember get member => entity.members[index];

  /// Use this to set the value of the database member and cause the attached
  /// listeners to be called.
  void set(dynamic value) {
    setController(value);
    setValue(value);
  }

  /// This can be overridden if the default string representation of the value
  /// is not suitable for display.
  void setController(dynamic value) {
    if (controller != null) {
      if (controller is TextEditingController) {
        final v = toDisplay(value);
        final String text =
            v is double && v == v.ceil() ? v.toInt().toString() : v.toString();
        controller.text = v == 0 ? "" : text;
      }
    }
  }

  /// This can be overridden if the value needs to be transformed in some way
  /// before being assigned to the database member.  Be sure to call
  /// `callListeners()` in your implementation!
  void setValue(dynamic value) {
    member.value = fromDisplay(value);
    callListeners();
  }

  /// Call each listener attached to this control object.
  void callListeners() {
    for (Function listener in _listeners) {
      listener();
    }
  }

  /// Add a listener to this control object.
  void addListener(Function() listener) {
    _listeners.add(listener);
  }

  /// This is a utility method for splitting a label-type string into separate
  /// space separated words.
  String splitWords(String start) {
    // Lower case everything, if it is all uppercase.
    RegExp re = RegExp(r"^[A-Z_\d]+$");
    RegExpMatch? match = re.firstMatch(start);
    if (match != null) {
      start = start.toLowerCase();
    }

    re = RegExp(r"^[a-z_\d]+$");
    match = re.firstMatch(start);
    if (match != null) {
      // Uppercase the first letter
      start = start[0].toUpperCase() + start.substring(1);
    } else {
      // Split words and uppercase each word
      final words = start.split(RegExp(r"(?<=[a-z])(?=[A-Z])"));
      words[0] = words[0][0].toUpperCase() + words[0].substring(1);
      start = "";
      for (var word in words) {
        if (start.isNotEmpty) {
          start += " ";
        }
        start += word;
      }
    }

    // Replace _ with space
    String copy = '';
    for (int i = 0; i < start.length; i++) {
      if (start[i] == '_') {
        copy = '$copy ';
        if (++i < start.length) {
          copy = copy + start[i].toUpperCase();
        }
      } else {
        copy = copy + start[i];
      }
    }
    return copy;
  }
}

/// The default input style for integers is a text input field.  Use this as
/// your control to use a number picker instead.
class IntDBMemberControl extends DBMemberControl {
  /// The minimum value a user can pick.
  final int minValue;

  /// The maximum value a user can pick.
  final int maxValue;

  /// The step between numbers.  Must be > 0.
  final int step;

  /// Direction of scrolling
  final Axis axis;

  /// The number picker width.
  final double width;

  /// The number picker height.
  final double height;

  /// Use this control if you want a number picker instead of numeric text
  /// input.
  IntDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    required this.minValue,
    required this.maxValue,
    this.step = 1,
    this.axis = Axis.vertical,
    super.label = "",
    this.height = 50,
    this.width = 100,
  }) {
    assert(step > 0);
  }
}

/// This provides a dropdown to select an individual enum value.
class EnumDBMemberControl extends DBMemberControl {
  /// An optional list of labels to associate with each enum member.
  List<String>? labels;

  /// Construct this control if you want to override the default list of labels
  /// that get dynamically created.
  EnumDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    this.labels,
  });
}

String _formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:00';

/// This determines the type of dialog associated with a DateTimeDBMemberControl
/// object.
enum DateTimeDBMemberControlType { date, time, both }

/// Provides a calendar and/or clock interface to create a DateTime object.
class DateTimeDBMemberControl extends DBMemberControl {
  DateTimeDBMemberControlType _type = DateTimeDBMemberControlType.both;

  /// The lowest year allowed when creating the calendar picker.
  int firstYear;

  /// Return the type of control(s) associated with this DateTime.
  DateTimeDBMemberControlType get type => _type;

  /// Set the type of control(s) associated with this DateTime.  When the type
  /// is changed, we need to reset the controller text.
  set type(DateTimeDBMemberControlType t) {
    _type = t;
    setController(member.value);
  }

  /// Construct a database member control object specifically for DateTime
  /// objects.
  DateTimeDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    super.controller,
    super.hint = "",
    this.firstYear = 0,
  }) {
    setController(member.value);
  }

  /// Set the controller text based on the type of display chosen.
  @override
  void setController(dynamic value) {
    switch (type) {
      case DateTimeDBMemberControlType.date:
        controller.text = value.toIso8601String().substring(0, 10);
        break;
      case DateTimeDBMemberControlType.time:
        controller.text = _formatTime(value.hour, value.minute);
        break;
      case DateTimeDBMemberControlType.both:
        controller.text = value.toIso8601String().substring(0, 19);
        break;
    }
  }
}

/// Use this enum to index into the bitField associated with the
/// DurationDBMemberControl object.  Set the bit to true to cause the number
/// picker to show controls for the specific time unit.
enum DurationDBMemberControlType {
  microseconds,
  milliseconds,
  seconds,
  minutes,
  hours
}

/// Provides a horizontal set of number pickers to create a Duration object.
class DurationDBMemberControl extends DBMemberControl {
  /// This bit field determines which number pickers will be displayed.  Use
  /// the DurationDBMemberControlType enum to index into this bit field.
  final bitField = BitField<DurationDBMemberControlType>(5);

  /// Default labels associated with the different number pickers.
  List<String> labels = [
    "Microseconds",
    "Milliseconds",
    "Seconds",
    "Minutes",
    "Hours"
  ];

  /// The step between numbers.  Must be > 0.
  int step;

  /// Direction of scrolling
  Axis axis;

  /// The number picker widths.
  double width;

  /// The number picker heights.
  double height;

  /// Should the set of number pickers expand the width of the container?
  bool expanded;

  final List<int> _values = [0, 0, 0, 0, 0];
  static const List<int> _conversion = [1, 1000, 1000000, 60000000, 3600000000];

  /// Construct a database member control object specifically for handling
  /// Duration objects.
  DurationDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    this.step = 1,
    this.axis = Axis.vertical,
    this.width = 100,
    this.height = 50,
    this.expanded = false,
  }) {
    assert(step > 0);
  }

  /// Set the database member value and then mirror that value as individual
  /// time units so that the number picker widgets show the current value.
  @override
  void setValue(dynamic value) {
    super.setValue(value);
    int micro = value.inMicroseconds;
    for (var type in DurationDBMemberControlType.values.reversed) {
      if (bitField[type]) {
        _values[type.index] = micro ~/ _conversion[type.index];
        micro -= _values[type.index] * _conversion[type.index];
      }
    }
  }
}

/// Provides a list of dismissible cards.
class ListDBMemberControl extends DBMemberControl {
  /// Use this dynamic function to generate the Card widget for each instance
  /// within the list.
  Card Function(BuildContext, EliteORMEditorStyle, dynamic)? renderCard;

  /// Implement a sorter for use with List.sort() for two database entities.
  /// This will determine the order in which the entities are listed on the
  /// screen.  The default implementation does nothing.
  int Function(dynamic a, dynamic b) sorter = (a, b) => 0;

  dynamic _lastAdded;

  /// Gets the last value added to the database member list.
  dynamic get lastAdded => _lastAdded;

  // Stores the individual height of a rendered card when using `renderListChooser`.
  double _individualHeight = 0;

  /// Construct a database member control object specifically for handling
  /// List objects.
  ListDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    this.renderCard,
    super.controller,
    super.hint = "",
    super.obscure = false,
  });

  /// Use this to add the value to the database member and cause the attached
  /// listeners to be called.
  void add(dynamic value) {
    member.value.add(value);
    _lastAdded = value;
    callListeners();
  }
}

/// Allows a user defined set of widgets to be displayed as part of the UI.
class CustomDBMemberControl extends DBMemberControl {
  /// Use this dynamic function to generate the widget to represent this
  /// database member.
  Widget Function(CustomDBMemberControl) createWidget;

  /// Create a custom database member control object.  The function specified
  /// in construction is responsible for creating the widgets necessary to
  /// represent the associated database member.
  CustomDBMemberControl({
    required super.tracker,
    required super.entity,
    required super.index,
    required this.createWidget,
    super.controller,
    super.hint = "",
    super.obscure = false,
  });
}

/// A control group contains a set of items to be grouped together in the UI.
class ControlGroup {
  /// The title for the group of editing widgets.
  final String title;

  /// The set of controls that belong to this group.
  final List<DBMemberControl> items;

  /// Each ControlGroup contains a title and a list of items that correspond
  /// to database object members.
  const ControlGroup({required this.title, required this.items});
}

class _IntInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.text.isNotEmpty && int.tryParse(newValue.text) == null
          ? oldValue
          : newValue;
}

class _DoubleInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.text.isNotEmpty && double.tryParse(newValue.text) == null
          ? oldValue
          : newValue;
}

class _WillPopConfig {
  /// The title of the popup dialog.
  String title = "Are you sure?";

  /// The body of the popup dialog.
  String body =
      "You have changes that have not been saved.  Do you want to discard them?";

  /// The string value displayed as the positive answer to the body question.
  String positive = "Yes";

  /// The string value displayed as the negative answer to the body question.
  String negative = "No";
}

/// This status enum is returned by the `save` method.  It indicates status
/// of the database operation and, additionally, the validity of the object
/// prior to being stored in the database.
enum SaveStatus { created, updated, invalid }

/// Derive your stateful widget class from EliteORMEditor instead of
/// StatefulWidget.  It will perform the same functionality but will return
/// a specialized State object specific to this editor.
abstract class EliteORMEditor extends StatefulWidget {
  /// Simple constructor that calls the super class.
  const EliteORMEditor({super.key});
}

/// Derive your state class from EliteORMEditorState instead of State.  This
/// will ensure that your widget class extends EliteORMEditor and still perform
/// the same functionality as the State class.
///
/// The `build` method is overridden to provide a default implementation that
/// gives the user the ability to edit and update elite_orm database objects.
abstract class EliteORMEditorState<T extends EliteORMEditor> extends State<T>
    with ModificationTracker {
  /// A set of controls that match the entity provided.
  final List<DBMemberControl> controls = [];

  /// Configuration for the onWillPop handler.
  final _WillPopConfig willPopConfig = _WillPopConfig();

  /// Override this in the child class to change the style.
  EliteORMEditorStyle get style => EliteORMEditorStyle();

  /// Creates a list of DBMemberControl objects stored in `controls` that
  /// correspond to the data members of the Entity passed in.  These can be cast
  /// to their derived type as needed in order to customize the settings for the
  /// control object.
  void createDefaultControls(Entity entity) {
    controls.clear();
    for (int index = 0; index < entity.members.length; index++) {
      final member = entity.members[index];
      if (member is EnumDBMember) {
        controls.add(EnumDBMemberControl(
          entity: entity,
          index: index,
          tracker: this,
        ));
      } else if (member is BoolDBMember) {
        controls.add(DBMemberControl(
          entity: entity,
          index: index,
          tracker: this,
        ));
      } else if (member is PrimitiveListDBMember) {
        controls.add(ListDBMemberControl(
          entity: entity,
          index: index,
          tracker: this,
        ));
      } else if (member is BinaryDBMember || member is ObjectDBMember) {
        controls.add(CustomDBMemberControl(
          entity: entity,
          index: index,
          createWidget: (control) => const SizedBox(),
          tracker: this,
        ));
      } else if (member is DateTimeDBMember) {
        controls.add(DateTimeDBMemberControl(
          entity: entity,
          index: index,
          controller: TextEditingController(),
          tracker: this,
        ));
      } else if (member is DurationDBMember) {
        controls.add(DurationDBMemberControl(
          entity: entity,
          index: index,
          tracker: this,
        ));
      } else {
        controls.add(DBMemberControl(
          entity: entity,
          index: index,
          controller: TextEditingController(),
          tracker: this,
        ));
      }
      controls.last.addListener(() => modified = true);
    }
  }

  /// Set each control to an initial value that comes from the Entity passed in.
  void initializeControlValues(Entity initial) {
    for (int i = 0; i < controls.length; i++) {
      controls[i].set(initial.members[i].value);
    }

    // Because each control has a listener upon construction, modified will
    // be true at this point.  Since we are loading from initial values, we need
    // to reset it to false.
    modified = false;
  }

  /// Add the same listener to each control.
  void addListeners(Function() listener) {
    for (var c in controls) {
      c.addListener(listener);
    }
  }

  /// Get a control by it's database key.
  DBMemberControl? getControl(String key) {
    for (var c in controls) {
      if (c.entity.members[c.index].key == key) {
        return c;
      }
    }
    return null;
  }

  /// Renders a modal bottom sheet to display a text input widget.
  ///
  /// title - The modal bottom sheet title.
  ///
  /// adder - The function to handle the string from the text field.
  ///
  /// onSubmit - Indicate if an onSubmit handler should be added to the text field.
  ///
  /// addText - The text to display instead of "Add".
  ///
  /// cancelText - The text to display instead of "Cancel".
  ///
  /// textFieldCreator - Optionally provide a function for creating text fields.
  /// If one is not provided, a default text field will be created.
  void renderTextAdder({
    required String title,
    required bool Function(String) adder,
    bool onSubmit = false,
    String addText = "Add",
    String cancelText = "Cancel",
    TextField Function(void Function(String)? submitter)? textFieldCreator,
  }) {
    // Nested function to avoid duplicate code
    void submit(String s) {
      if (adder(s)) {
        setState(() {});
        Navigator.of(context).pop(true);
      }
    }

    TextField field = textFieldCreator == null
        ? TextField(
            controller: TextEditingController(),
            onSubmitted: onSubmit ? submit : null)
        : textFieldCreator(onSubmit ? submit : null);

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (BuildContext context, StateSetter internalState) {
              return Column(
                children: [
                  Padding(
                    padding: style.columnPadding,
                    child: Text(title, style: style.titleText),
                  ),
                  Expanded(
                    child: Padding(
                      padding: style.columnPadding,
                      child: field,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text(cancelText),
                      ),
                      TextButton(
                        onPressed: () => submit(field.controller!.text),
                        child: Text(addText),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        });
  }

  Widget _translateCustomItem(CustomDBMemberControl item) =>
      item.createWidget(item);

  Widget _translateBoolItem(DBMemberControl item) {
    Widget child;
    if (item.checkbox) {
      child = Checkbox(
        key: ObjectKey(item.member),
        value: item.member.value,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (v) => setState(() => item.setValue(v)),
      );
    } else {
      child = Switch(
        key: ObjectKey(item.member),
        value: item.member.value,
        activeColor: Theme.of(context).colorScheme.primary,
        onChanged: (v) => setState(() => item.setValue(v)),
      );
    }
    return item.label == null
        ? child
        : Row(children: [child, Text(item.label!, style: style.cardTitleText)]);
  }

  Widget _translateDateTimeItem(DBMemberControl item) {
    DateTimeDBMemberControlType type = DateTimeDBMemberControlType.both;
    int firstYear = 0;
    if (item is DateTimeDBMemberControl) {
      type = item.type;
      firstYear = item.firstYear;
    }
    return Padding(
      key: ObjectKey(item.member),
      padding: style.textPadding,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              readOnly: true,
              controller: item.controller,
              decoration: style.hintDecoration(item.hint),
            ),
          ),
          if (!item.readOnly)
            IconButton(
              icon: Icon(
                type == DateTimeDBMemberControlType.time
                    ? Icons.access_time_outlined
                    : Icons.calendar_month,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: () async {
                final RegExp re = RegExp(r"^(\d\d):(\d\d)(:(\d\d))?$");
                DateTime? parse(String text) {
                  DateTime? parsed = DateTime.tryParse(text);
                  if (parsed != null) {
                    return parsed;
                  }
                  RegExpMatch? match = re.firstMatch(text);
                  if (match != null) {
                    final int hour = int.tryParse(match[1]!) ?? 0;
                    final int minute = int.tryParse(match[2]!) ?? 0;
                    final int second =
                        match[4] == null ? 0 : int.tryParse(match[4]!) ?? 0;
                    return DateTime(firstYear, 1, 1, hour, minute, second);
                  }
                  return null;
                }

                final DateTime initial =
                    parse(item.controller.text) ?? DateTime.now();
                bool modified = false;
                if (type == DateTimeDBMemberControlType.date ||
                    type == DateTimeDBMemberControlType.both) {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: DateTime(firstYear),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    modified = true;
                    item.controller.text =
                        date.toIso8601String().substring(0, 10);
                  }
                }
                if (mounted &&
                    (type == DateTimeDBMemberControlType.time ||
                        type == DateTimeDBMemberControlType.both)) {
                  final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(initial));
                  if (time != null) {
                    modified = true;
                    if (type == DateTimeDBMemberControlType.time) {
                      item.controller.text =
                          _formatTime(time.hour, time.minute);
                    } else if (type == DateTimeDBMemberControlType.both) {
                      item.controller.text +=
                          "T${_formatTime(time.hour, time.minute)}";
                    }
                  }
                }
                if (modified) {
                  final DateTime? value = parse(item.controller.text);
                  if (value != null) {
                    item.setValue(value);
                  }
                }
              },
            ),
        ],
      ),
    );
  }

  int _maxDurationValue(DurationDBMemberControlType type, dynamic bitField) {
    for (int i = type.index + 1;
        i < DurationDBMemberControlType.values.length;
        i++) {
      if (bitField[DurationDBMemberControlType.values[i]]) {
        // Use max value for type
        return type == DurationDBMemberControlType.minutes ||
                type == DurationDBMemberControlType.seconds
            ? 59
            : type == DurationDBMemberControlType.microseconds
                ? 99999
                : 999;
      }
    }
    // Use max value for single
    return type == DurationDBMemberControlType.microseconds ? 99999 : 999;
  }

  Container _translateDurationItem(DurationDBMemberControl item) {
    bool first = true;
    final List<Widget> children = [];

    int label = DurationDBMemberControlType.values.length - 1;
    for (var type in DurationDBMemberControlType.values.reversed) {
      if (item.bitField[type]) {
        final bool hasLabel = (label >= 0 && label < item.labels.length);
        // Only add a separator when adding two or more number pickers.
        if (first) {
          first = false;
        } else {
          double padding = 3;
          if (hasLabel) {
            final painter = TextPainter(
                text: TextSpan(text: ":", style: style.durationLabelText),
                maxLines: 1,
                textDirection: TextDirection.ltr)
              ..layout();
            padding += painter.size.height;
          }
          children.add(
            // This padding pushes the colon up to match the height of the
            // center of the number picker.
            Padding(
              padding: EdgeInsets.only(bottom: padding),
              child: Text(":", style: style.durationNumberStyle(context)),
            ),
          );
        }

        final int maxValue = _maxDurationValue(type, item.bitField);
        final Widget inner = Padding(
          padding: style.durationLabelPadding,
          child: Column(
            children: [
              NumberPicker(
                selectedTextStyle: style.durationNumberStyle(context),
                zeroPad: true,
                value: item._values[type.index],
                minValue: 0,
                maxValue: maxValue,
                step: item.step,
                axis: item.axis,
                itemWidth: item.width,
                itemHeight: item.height,
                infiniteLoop: maxValue <= 59,
                onChanged: (value) => setState(() {
                  // This updates the individual number picker value.
                  item._values[type.index] = value;

                  // This sets the database member value and all of the number
                  // picker values based on the new duration.  This should not
                  // cause any roll-over, assuming that _maxDurationValue
                  // returns the correct value.
                  item.setValue(
                    Duration(
                      hours:
                          item._values[DurationDBMemberControlType.hours.index],
                      minutes: item
                          ._values[DurationDBMemberControlType.minutes.index],
                      seconds: item
                          ._values[DurationDBMemberControlType.seconds.index],
                      milliseconds: item._values[
                          DurationDBMemberControlType.milliseconds.index],
                      microseconds: item._values[
                          DurationDBMemberControlType.microseconds.index],
                    ),
                  );
                }),
              ),
              if (hasLabel)
                Text(item.labels[label], style: style.durationLabelText),
            ],
          ),
        );
        children.add(
          item.expanded ? Expanded(child: inner) : inner,
        );
      }
      label--;
    }
    return Container(
      key: ObjectKey(item.member),
      margin: style.textPadding,
      decoration: style.containerOutline(context),
      child: Row(children: children),
    );
  }

  Widget _translateEnumItem(DBMemberControl item) {
    final EnumDBMember member = (item.member as EnumDBMember);
    List<String>? labels;
    if (item is EnumDBMemberControl) {
      labels = item.labels;
    }
    labels ??= member.values.map((e) {
      final String str = e.toString();
      final String text = str.substring(str.indexOf('.') + 1);
      return item.splitWords(text);
    }).toList();

    return Container(
      key: ObjectKey(item.member),
      margin: style.textPadding,
      padding: style.innerPadding,
      decoration: style.containerOutline(context),
      child: DropdownButton<Enum>(
        value: member.value,
        isExpanded: true,
        onChanged: (Enum? e) {
          setState(() {
            for (var v in member.values) {
              if (v == e!) {
                item.setValue(v);
                break;
              }
            }
          });
        },
        items: member.values.map<DropdownMenuItem<Enum>>((Enum value) {
          return DropdownMenuItem<Enum>(
            value: value,
            child: Text(item.splitWords(value.index < labels!.length
                ? labels[value.index]
                : "Missing Label")),
          );
        }).toList(),
      ),
    );
  }

  Widget _translateListItem(DBMemberControl item) {
    int index = 0;
    final List<Widget> children = [];
    final Random rand = Random();

    // Sort the list if the control item is a list control.
    if (item is ListDBMemberControl) {
      item.member.value.sort(item.sorter);
    }

    for (var v in item.member.value) {
      // This could still result in a problem deleting from the front of the
      // list.  If there are multiple list items of the exact same value, when
      // the dismissible list is recreated we could have a key that was the same
      // as the dismissed item.  If that happens, there will be an exception
      // when everything is redrawn.
      final int next = rand.nextInt(0xffffffff);
      children.add(
        Dismissible(
          background: Container(
            color: Theme.of(context).colorScheme.error,
            child: Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(left: style.listTrashcanPadding),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.only(right: style.listTrashcanPadding),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          onDismissed: (direction) => setState(() {
            item.member.value.remove(v);
            item.callListeners();
          }),
          direction: DismissDirection.horizontal,
          key: Key("$v$index$next"),
          child: item is ListDBMemberControl && item.renderCard != null
              ? item.renderCard!(context, style, v)
              : Card(
                  shape: style.cardShape(context),
                  child: ListTile(
                    title: Text(
                        v.toString() +
                            (item.label == null ? "" : " ${item.label!}"),
                        style: style.cardTitleText),
                  ),
                ),
        ),
      );
      index++;
    }

    return Padding(
      key: ObjectKey(item.member),
      padding: style.textPadding,
      child: Column(children: children),
    );
  }

  Widget _translateBasicItem(DBMemberControl item) {
    final value = item.member.value;
    final bool isNumber = value is int || value is double;
    final TextInputType keyboardType =
        isNumber ? TextInputType.number : TextInputType.text;
    final List<TextInputFormatter> formatters = [];
    Function fromString;
    if (value is int) {
      formatters.add(_IntInputFormatter());
      fromString = (s) => int.tryParse(s) ?? 0;
    } else if (isNumber) {
      if (item.asInt) {
        item.setController(value.toInt());
        formatters.add(_IntInputFormatter());
      } else {
        formatters.add(_DoubleInputFormatter());
      }
      fromString = (s) => double.tryParse(s) ?? 0;
    } else {
      fromString = (s) => s;
    }

    return Padding(
      key: ObjectKey(item.member),
      padding: style.textPadding,
      child: Row(
        children: [
          Expanded(
            flex: style.textInputFlex,
            child: item.completeValues == null || item.completeValues!.isEmpty
                ? TextField(
                    readOnly: item.readOnly,
                    controller: item.controller,
                    decoration: style.hintDecoration(item.hint),
                    onChanged: (s) => item.setValue(fromString(s)),
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    obscureText: item.obscure && item._obscured,
                  )
                : AutoCompleteTextField(
                    textValues: item.completeValues!,
                    controller: item.controller,
                    decoration: style.hintDecoration(item.hint),
                    onChanged: (s) => item.setValue(fromString(s)),
                    keyboardType: keyboardType,
                    inputFormatters: formatters,
                    obscureText: item.obscure && item._obscured,
                  ),
          ),
          if (item.label != null)
            Padding(padding: style.labelPadding, child: Text(item.label!)),
          if (item.obscure)
            IconButton(
              onPressed: () => setState(() {
                // Flip the obscured flag and switch the icon.
                item._obscured ^= true;
                item._eye = item._obscured
                    ? Icons.remove_red_eye
                    : Icons.remove_red_eye_outlined;
              }),
              icon: Icon(item._eye),
            ),
        ],
      ),
    );
  }

  Widget _translateIntItem(IntDBMemberControl item) {
    return Column(
      key: ObjectKey(item.member),
      children: [
        NumberPicker(
          zeroPad: true,
          value: item.member.value,
          minValue: item.minValue,
          maxValue: item.maxValue,
          step: item.step,
          axis: item.axis,
          itemWidth: item.width,
          itemHeight: item.height,
          onChanged: (value) => setState(() => item.setValue(value)),
        ),
        if (item.label != null && item.label!.isNotEmpty)
          Text(item.label!, style: style.durationLabelText),
      ],
    );
  }

  /// Translate the ControlGroup into a list of widgets to be used to make up
  /// a portion of the editing screen.
  List<Widget> translateGroup(ControlGroup group) {
    final List<Widget> widgets = [];
    if (group.title.isNotEmpty) {
      widgets.add(
        Padding(
          key: ObjectKey(group.title),
          padding: style.columnPadding,
          child: Text(group.title, style: style.titleText),
        ),
      );
    }

    Container? previous;
    for (var item in group.items) {
      if (item is CustomDBMemberControl) {
        widgets.add(_translateCustomItem(item));
      } else if (item is IntDBMemberControl) {
        widgets.add(_translateIntItem(item));
      } else if (item.member is BoolDBMember) {
        widgets.add(_translateBoolItem(item));
      } else if (item.member is DateTimeDBMember) {
        widgets.add(_translateDateTimeItem(item));
      } else if (item is DurationDBMemberControl &&
          item.member is DurationDBMember) {
        final Container dc = _translateDurationItem(item);
        if (previous == null) {
          previous = dc;
          widgets.add(dc);
        } else {
          // TBD: Somehow incorporate Expanded into each child
          final Row row = previous.child as Row;
          row.children.addAll((dc.child as Row).children);
        }
      } else if (item.member is EnumDBMember) {
        widgets.add(_translateEnumItem(item));
      } else if (item.member is PrimitiveListDBMember) {
        widgets.add(_translateListItem(item));
      } else {
        widgets.add(_translateBasicItem(item));
      }
    }
    return widgets;
  }

  /// Translate a list of groups into a Widget list.  Use this method in your
  /// implementation of `buildGroups()`.
  List<Widget> translateGroups(List<ControlGroup> groups) {
    final List<Widget> content = [];
    for (var group in groups) {
      content.addAll(translateGroup(group));
    }
    return content;
  }

  /// Insert an element into the Entity member list associated with this control
  /// object.
  Widget _renderItemButton(
    DBMemberControl control,
    dynamic item,
    Function? toString,
    Function? toSubtitle,
    bool allowDuplicates,
  ) {
    return GestureDetector(
      key: ObjectKey(item),
      child: Card(
        shape: style.cardShape(context),
        child: ListTile(
          title: Text(
            toString == null ? item.toString() : toString(item),
            style: style.cardTitleText,
          ),
          subtitle: toSubtitle == null ? null : Text(toSubtitle(item)),
        ),
      ),
      onTap: () {
        setState(() {
          if (allowDuplicates || !control.member.value.contains(item)) {
            if (control is ListDBMemberControl) {
              control.add(item);
            } else {
              // Add the item and call the listeners on the control object.
              control.member.value.add(item);
              control.callListeners();
            }
          }
        });
        Navigator.pop(context);
      },
    );
  }

  /// Show a modal bottom sheet that contains a list of Card buttons.  When
  /// one of the Card buttons is tapped, it will add that item to the list
  /// associated with the control object.
  Future<void> renderListChooser({
    required DBMemberControl control,
    required String title,
    required List items,
    Function? toString,
    Function? toSubtitle,
    int? index,
    bool allowDuplicates = false,
  }) async {
    if (control.entity.members[control.index] is PrimitiveListDBMember) {
      final bool isListControl = (control is ListDBMemberControl);
      final ScrollController? controller = (index != null &&
              isListControl &&
              control._individualHeight != 0 &&
              items.isNotEmpty
          ? ScrollController(
              initialScrollOffset: index * control._individualHeight)
          : null);

      showModalBottomSheet(
          context: context,
          builder: (builder) {
            return Column(
              children: [
                Padding(
                  padding: style.columnPadding,
                  child: Text(title, style: style.titleText),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      // If the user has a list control, we will try to find
                      // out the height of the first child rendered in the list
                      // view so that we can keep it for later use.  On
                      // subsequent times into this method, with the same
                      // control object, we can scroll the ListView to the
                      // last item selected.
                      if (isListControl && control._individualHeight == 0) {
                        final renderObject = context.findRenderObject();
                        if (renderObject != null) {
                          final renderBox =
                              (renderObject as RenderSliverList).firstChild;
                          if (renderBox != null) {
                            control._individualHeight = renderBox.size.height;
                          }
                        }
                      }
                      return _renderItemButton(
                        control,
                        items[index],
                        toString,
                        toSubtitle,
                        allowDuplicates,
                      );
                    },
                  ),
                ),
              ],
            );
          });
    }
  }

  /// Override this in the child class to create your groups of settings.
  ///
  /// Use the translateGroup method to translate your group into a set of
  /// widgets that will make up the editing portion of the settings screen.
  List<Widget> buildGroups();

  /// Configure the text portion of this dialog by modifying the
  /// `willPopConfig` object.  Override this in the child class, if this
  /// implementation does not suit your needs.  Return false to keep the user
  /// on the editing screen.
  void onWillPop(bool didPop) async {
    if (!didPop) {
      final bool shouldPop = modified
          ? await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(willPopConfig.title),
                  content: Text(willPopConfig.body),
                  actions: <Widget>[
                    TextButton(
                      // If the user presses no, we pop false so that the navigation
                      // does not proceed back to the previous screen.
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(willPopConfig.negative),
                    ),
                    TextButton(
                      // If the user presses yes, we pop true so that after this
                      // dialog is destroyed, we navigate back to the previous
                      // screen.
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(willPopConfig.positive),
                    ),
                  ],
                ),
              ) ??
              // Down here, the dialog was dismissed by touching outside of it,
              // which we will consider as the user telling us that they want to
              // stay on the current screen.
              false
          // There were no modifications, so we should pop.
          : true;

      // True indicates that the screen can proceed to the previous navigation
      // point.  The user decided to discard the changes.
      if (shouldPop && mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  /// Override this in your child class if this implementation does not suit
  /// your needs.
  Widget renderContent() => ListView(children: buildGroups());

  /// Override this such that it verifies that the object about to be stored
  /// in the database contains valid data.  The default implementation only
  /// works with string primary keys.
  bool isValid(Entity entity) {
    for (int i = 0; i < entity.members.length; i++) {
      if (i == 0 || entity.members[i].primary) {
        // Numbers, dates, durations, and enums will always contain values.
        // In general, strings shouldn't be empty to ensure uniqueness.
        if (entity.members[i].value is String &&
            entity.members[i].value.isEmpty) {
          return false;
        }
      }
    }
    return true;
  }

  /// Determine if any of the primary keys have changed.
  bool hasPrimaryChanged(Entity? original, Entity entity) {
    if (original != null) {
      for (int i = 0; i < entity.members.length; i++) {
        if (i == 0 || entity.members[i].primary) {
          if (original.members[i].value != entity.members[i].value) {
            return true;
          }
        }
      }
    }
    return false;
  }

  /// Provide the Bloc, the original Entity (if available) and the Entity to
  /// be stored in the database.  It will either create or update the database
  /// entry, if the Entity is deemed valid, and return status.
  Future<SaveStatus> save(Bloc bloc, Entity? original, Entity entity) async {
    SaveStatus status = SaveStatus.invalid;
    if (isValid(entity)) {
      if (original == null) {
        await bloc.create(entity);
        status = SaveStatus.created;
      } else {
        if (hasPrimaryChanged(original, entity)) {
          // Changing the the primary key is the same as creating
          // a new object.  We have to create the new object and delete the old
          // one.  There's no way to just "rename" an entry in the database.
          await bloc.create(entity);
          await bloc.delete(original);
        } else {
          // If the primary key has not changed, then we can update.
          await bloc.update(entity);
        }
        status = SaveStatus.updated;
      }
    }
    return status;
  }

  /// Override this in your child class and return a Row containing a list of
  /// widgets to show a bottom navigation bar.
  Row? renderBottomIcons() => null;

  /// Override this in your child class if this implementation does not suit
  /// your needs.
  Widget? renderBottomNavigationBar() {
    final Row? bottom = renderBottomIcons();
    return bottom == null
        ? null
        : BottomAppBar(
            child: Container(
              padding: style.bottomBarPadding,
              decoration: style.bottomBarDecoration(context),
              child: bottom,
            ),
          );
  }

  /// Override this in your child class to provide the AppBar title.
  String get title;

  /// By default, return an AppBar widget with a text title.
  PreferredSizeWidget renderAppBar() => AppBar(title: Text(title));

  /// The default implementation uses a simple Scaffold wrapped by a
  /// PopScope.  Override this in your child class if this implementation
  /// does not suit your needs.
  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        onPopInvoked: onWillPop,
        child: Scaffold(
          appBar: renderAppBar(),
          body: SafeArea(child: renderContent()),
          bottomNavigationBar: renderBottomNavigationBar(),
        ),
      );
}
