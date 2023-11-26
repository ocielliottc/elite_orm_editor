import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:elite_orm/elite_orm.dart';
import 'package:elite_orm_editor/elite_orm_editor.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'picture.dart';
import '../model/kitchen_sink.dart';
import '../database/database.dart';
import '../style/style.dart';

// There is only one Bloc object that we will use on both this screen and the
// home screen.
final kitchenSinkBloc = Bloc(KitchenSink(), DatabaseProvider.database);

final List<Color> _colors = [
  Colors.black,
  Colors.white,
  Colors.grey,
  Colors.grey.shade300,
];

class EditKitchenSink extends EliteORMEditor {
  final KitchenSink? kitchenSink;

  const EditKitchenSink({super.key, this.kitchenSink});

  @override
  State<EditKitchenSink> createState() => EditKitchenSinkState();
}

class EditKitchenSinkState extends EliteORMEditorState<EditKitchenSink> {
  // Content editing
  KitchenSink storage = KitchenSink();
  final List<ControlGroup> _groups = [];

  // Content editing: camera/image
  late Future<List<CameraDescription>> _cameras;
  Image? _image;

  @override
  String get title =>
      widget.kitchenSink == null ? "Add KitchenSink" : "Edit KitchenSink";

  @override
  EliteORMEditorStyle get style => Style();

  @override
  void initState() {
    super.initState();
    _cameras = availableCameras();

    // Create the default set of database member controls.
    createDefaultControls(storage);

    // Add a set of auto-complete text strings.
    controls[0].completeValues = ["Main", "Secondary", "External"];

    // Replace the default control (integer text input) with a number picker.
    controls[1] = IntDBMemberControl(
      entity: storage,
      index: 1,
      minValue: 1,
      maxValue: 3,
      axis: Axis.horizontal,
      tracker: this,
    );

    // Add a label to the control.
    controls[2].label = "cm";

    // Change the bool control to a Checkbox (instead of a Switch).
    controls[4].checkbox = true;

    // Add a label to the bool control.
    controls[4].label = "Instant Hot Water";

    // Set the createWidget method with something that actually does something.
    (controls[5] as CustomDBMemberControl).createWidget = _createImageWidget;

    // Tell the DateTimeDBMemberControl to only display a date picker.
    (controls[6] as DateTimeDBMemberControl).type =
        DateTimeDBMemberControlType.date;

    // Tell the DurationDBMemberControl to show minutes and seconds.
    DurationDBMemberControl duration = (controls[7] as DurationDBMemberControl);
    duration.bitField[DurationDBMemberControlType.minutes] = true;
    duration.bitField[DurationDBMemberControlType.seconds] = true;

    controls[8].label = "cm";

    // Set the createWidget method to a color picker
    (controls[10] as CustomDBMemberControl).createWidget = _createColorPicker;

    // Fill in the widgets with data.
    if (widget.kitchenSink != null) {
      initializeControlValues(widget.kitchenSink!);
    }
  }

  static Future _errorShow(BuildContext context, String body) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Ok"),
          ),
        ],
      ),
    );
  }

  Widget _createImageWidget(CustomDBMemberControl control) {
    return Padding(
      padding: style.columnPadding,
      child: Row(
        children: <Widget>[
          IconButton(
            onPressed: () async {
              var status = await Permission.camera.status;
              if (!status.isGranted) {
                await Permission.camera.request();
                status = await Permission.camera.status;
              }
              if (status.isGranted) {
                List<CameraDescription> cameras = await _cameras;
                if (mounted) {
                  if (cameras.isEmpty) {
                    _errorShow(
                        context, "It appears that a camera is not available.");
                  } else {
                    final String? result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Picture(camera: cameras.first),
                      ),
                    );
                    if (result != null && result.isNotEmpty) {
                      setState(() {
                        final file = File(result);
                        final List<int> imageBytes = file.readAsBytesSync();
                        file.delete();

                        setState(() =>
                            controls[5].set(Uint8List.fromList(imageBytes)));
                      });
                    }
                  }
                }
              }
            },
            icon: const Icon(Icons.camera_alt),
          ),
          if (_image != null)
            GestureDetector(
                onLongPress: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Are you sure?"),
                      content: const Text("Do you want to delete this image?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("No"),
                        ),
                        TextButton(
                          onPressed: () {
                            controls[5].set(Uint8List(0));
                            setState(() => _image = null);
                            Navigator.of(context).pop(true);
                          },
                          child: const Text("Yes"),
                        ),
                      ],
                    ),
                  );
                },
                child: _image!),
        ],
      ),
    );
  }

  Widget _pickerLayout(
      BuildContext context, List<Color> colors, PickerItem child) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    final count = orientation == Orientation.portrait ? 4 : 6;
    return SizedBox(
      width: double.maxFinite,
      height: 120.0 * ((colors.length > 6 ? 6 : colors.length) / count).ceil(),
      child: GridView.count(
        crossAxisCount: count,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: colors.map((e) => child(e)).toList(),
      ),
    );
  }

  Widget _createColorPicker(CustomDBMemberControl control) {
    return BlockPicker(
      availableColors: _colors,
      pickerColor: control.member.value,
      onColorChanged: (c) => control.set(DBColor(c.value)),
      layoutBuilder: _pickerLayout,
    );
  }

  void _saveKitchenSink() async {
    try {
      final SaveStatus status =
          await save(kitchenSinkBloc, widget.kitchenSink, storage);
      String message;
      switch (status) {
        case SaveStatus.created:
          message = "Kitchen Sink Saved";
          modified = false;
          break;
        case SaveStatus.updated:
          message = "Kitchen Sink Updated";
          modified = false;
          break;
        case SaveStatus.invalid:
          message = "Invalid Kitchen Sink";
          break;
      }

      // Because we're using the build context after an await, we need to
      // ensure that this widget is still mounted before using it.
      if (status != SaveStatus.invalid && mounted) {
        Navigator.pop(context);
      }

      // Same here.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (err) {
      _errorShow(context, err.toString());
    }
  }

  void _deleteKitchenSink() async {
    if (widget.kitchenSink != null) {
      try {
        await kitchenSinkBloc.delete(widget.kitchenSink);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (err) {
        _errorShow(context, err.toString());
      }
    }
  }

  void _renderGarbageDisposalChooser() async {
    if (controls[9].member.value.length < storage.bays) {
      final List<GarbageDisposal> list = [
        GarbageDisposal("InSinkErator", "Badger 5"),
        GarbageDisposal("InSinkErator", "Evolution", .75),
        GarbageDisposal("MOEN", "Host Series", .75),
        GarbageDisposal("Waste King", "Legend", 1.0),
      ];
      renderListChooser(
          control: controls[9],
          title: "Garbage Disposal",
          items: list,
          toSubtitle: (g) => "${g.horsePower} HP");
    }
  }

  bool _addBayDepth(String text) {
    double? value = double.tryParse(text);
    if (value == null || value <= 0) {
      return false;
    } else {
      setState(() => (controls[8] as ListDBMemberControl).add(value));
      return true;
    }
  }

  void _renderBayDepthAdder() {
    if (controls[8].member.value.length < storage.bays) {
      return renderTextAdder(
        title: "Add Bay Depth",
        adder: _addBayDepth,
        onSubmit: true,
        textFieldCreator: (submitter) => TextField(
            keyboardType: TextInputType.number,
            autocorrect: false,
            decoration: style.hintDecoration(),
            autofocus: true,
            onSubmitted: submitter),
      );
    }
  }

  @override
  Row? renderBottomIcons() {
    final List<Widget> children = [
      IconButton(
        icon: Icon(
          Icons.add_box_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        iconSize: style.iconSize,
        onPressed: _renderBayDepthAdder,
      ),
      IconButton(
        icon: Icon(
          Icons.add_business_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        iconSize: style.iconSize,
        onPressed: _renderGarbageDisposalChooser,
      ),
      SizedBox(width: style.iconSize),
      SizedBox(width: style.iconSize),
      IconButton(
        icon: Icon(
          Icons.save,
          color: Theme.of(context).colorScheme.primary,
        ),
        iconSize: style.iconSize,
        onPressed: _saveKitchenSink,
      ),
    ];
    if (widget.kitchenSink != null) {
      children.add(
        IconButton(
          icon: Icon(
            Icons.delete_forever,
            color: Theme.of(context).colorScheme.primary,
          ),
          iconSize: style.iconSize,
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Are you sure?"),
                content: const Text(
                    "Are you sure you want to delete this kitchen sink?"),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("No"),
                  ),
                  TextButton(
                    onPressed: () {
                      _deleteKitchenSink();
                      Navigator.of(context).pop(true);
                    },
                    child: const Text("Yes"),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: children);
  }

  @override
  List<Widget> buildGroups() {
    if (_groups.isEmpty) {
      _groups.add(ControlGroup(title: "Location", items: [controls[0]]));
      _groups
          .add(ControlGroup(title: "Bays", items: [controls[1], controls[8]]));
      _groups.add(ControlGroup(title: "Sprayer Hose", items: [controls[2]]));
      _groups.add(ControlGroup(title: "Mount Style", items: [controls[3]]));
      _groups.add(ControlGroup(title: "", items: [controls[4]]));
      _groups.add(ControlGroup(title: "Sink Color", items: [controls[10]]));
      _groups.add(ControlGroup(title: "Image", items: [controls[5]]));
      _groups.add(ControlGroup(title: "Date Installed", items: [controls[6]]));
      _groups.add(ControlGroup(title: "Fill Time", items: [controls[7]]));
      _groups
          .add(ControlGroup(title: "Garbage Disposals", items: [controls[9]]));
    }

    if (storage.image.isNotEmpty) {
      _image = Image.memory(storage.image, scale: 2);
    }

    return translateGroups(_groups);
  }
}
