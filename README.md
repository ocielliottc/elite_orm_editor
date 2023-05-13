# elite_orm_editor

[![Version](https://img.shields.io/pub/v/elite_orm_editor)](https://pub.dev/packages/elite_orm_editor)
[![License](https://img.shields.io/github/license/ocielliottc/elite_orm_editor)](https://github.com/elliottc/elite_orm_editor)

A set of widgets specifically designed to work with [elite_orm](https://pub.dev/packages/elite_orm).

## Getting Started

In your flutter project add the dependency:

```yml
dependencies:
  ...
  elite_orm_editor:
```

## Usage example

Import `elite_orm_editor.dart`

```dart
import 'package:elite_orm_editor/elite_orm_editor.dart';
```

### Creating an editor widget

Your widget class will extend `EliteORMEditor`.

```dart
class TeamEdit extends EliteORMEditor {
  final Team? team;
  const TeamEdit({super.key, this.team});

  @override
  State<TeamEdit> createState() => _TeamEditState();
}
```

### Creating the editor widget state.
This class will do the bulk of your editor widget.

```dart
class _TeamEditState extends EliteORMEditorState<TeamEdit> {
  Team storage = Team();
  final List<ControlGroup> _groups = [];

  @override
  void initState() {
    super.initState();

    createDefaultControls(storage);

    // Fill in the widgets with data.
    if (widget.team != null) {
      initializeControlValues(widget.widget!);
    }
  }

  void _saveTeam() async {
    try {
      final SaveStatus status = await save(teamBloc, widget.team, storage);
      String message;
      switch (status) {
        case SaveStatus.created:
          message = "Team Saved";
          modified = false;
          break;
        case SaveStatus.updated:
          message = "Team Updated";
          modified = false;
          break;
        case SaveStatus.invalid:
          message = "Invalid Team";
          break;
      }

      // Because we're using the build context after an await, we need to
      // ensure that this widget is still mounted before using it.
      if (!modified && mounted) {
        Navigator.pop(context);
      }

      // Same here.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (err) {
      ErrorDialog.show(context, err.toString());
    }
  }

  @override
  List<Widget> buildGroups() {
    //  Initialize your control groups here instead of in initState() in the
    // event that you use AppLocalizations.of(context) to support
    // internationalization.
    if (_groups.isEmpty) {
      _groups.add(ControlGroup(title: "Team Name", items: [controls[0]]));
      _groups.add(ControlGroup(title: "Schedule Website", items: [controls[1]]));
      _groups.add(ControlGroup(title: "Teammates", items: [controls[2]]));
    }
    return translateGroups(_groups);
  }

  @override
  String get title => "Edit Team";
}
```

Click [here](https://github.com/ocielliottc/elite_orm_editor/tree/main/example/lib) to see a more detailed example.

## The EliteORMEditor class

Extend the `EliteORMEditor` class instead of the `StatefulWidget` class.

## The EliteORMEditorState class

Extend the `EliteORMEditorState` class instead of the `State` class.  It will provide a framework for creating an editor screen for a single type of database Entity.

### Required Methods

`String get title`

This abstract attribute provides the title of the editing screen.   

`List<Widget> buildGroups()`

This abstract method is how you provide information to the library to ensure that the editing controls get grouped together properly.

If you have a list of groups, your implementation can typically return the result of `translateGroups`.

### Methods available to the EliteORMEditorState class

`EliteORMEditorStyle get style`

The default implementation provides an `EliteORMEditorStyle` object containing methods that help determine the appearance of the editor screen.

`void createDefaultControls(Entity entity)`

This method creates a set of default controls to be used to modify the individual data members within the entity.

`void initializeControlValues(Entity initial)`

Sets each control in the `controls` array to an initial value that comes from the Entity passed in.

`void addListeners(Function() listener)`

Add a listener to every single control in the `controls` array.

`DBMemberControl? getControl(String key)`

Get a control from the `controls` array based on the key of the database member of the Entity. 

`void renderTextAdder({required String title, required bool Function(String) adder, required TextField field, String? addText, String? cancelText})`

This method creates a modal bottom sheet with a single text field entry.  It is used to add text items to a list.

`List<Widget> translateGroup(ControlGroup group)`

Translate a single ControlGroup into a list of widgets to be used to make up a portion of the editing screen.

`List<Widget> translateGroups(List<ControlGroup> groups)`

Translate a list of groups into a Widget list.  Use this method in your implementation of `buildGroups()`.

`Future<void> renderListChooser({
required DBMemberControl control,
required String title,
required List items,
Function? toString,
Function? toSubtitle,
}) async`

`Future<bool> onWillPop() async`

Override this in your child class.  It will allow you to prompt the user to save their changes if they haven't already done so.

`Widget renderContent()`

The default implementation creates a `ListView` with the `buildGroups()` result.

`bool isValid(Entity entity)`

The default implementation looks at all parts of the primary key that are of type String and checks to see if any are empty.  If one or more is empty, it returns false.  Otherwise, it returns true.

`bool hasPrimaryChanged(Entity? original, Entity entity)`

Does a comparison of each part of the primary key.  If any have changed, it returns true.

`Future<SaveStatus> save(Bloc bloc, Entity? original, Entity entity) async`

This method will either create or update the database entry based on `entity`, if it is deemed valid, and return status.

`Row? renderBottomIcons()`

Override this in your child class and return a Row containing a list of  widgets to show a bottom navigation bar.

The default implementation returns null.

`Widget? renderBottomNavigationBar()`

This method creates a `BottomAppBar` if `renderBottomIcons()` does not return null.

`PreferredSizeWidget renderAppBar()`

The default implementation returns an AppBar widget with a text title.

`Widget build(BuildContext context)`

he default implementation uses a simple Scaffold wrapped by a WillPopScope.  Override this in your child class if this implementation does not suit your needs.

## The EliteORMList class

Extend the `EliteORMList` class instead of the `StatefulWidget` class.

## The EliteORMListState class

Extend the `EliteORMListState` class instead of the `State` class.  It will provide a framework for creating a list of Card widgets that represent each Entity in the database.

### Required Methods

`Bloc get bloc`

Provide the bloc for your database entities.

`String get title`

This abstract attribute provides the title of the list screen.

`Widget getEditor([Entity? entity])`

Return a widget that will create an "editing" screen when the individual card is tapped.

`String getEntityTitle(Entity entity)`

Return a string that will be used as the Card title.

### Methods available to the EliteORMListState class

`String get loading`

Returns a string to indicate to the user that the data is loading.

`String? getEntitySubtitle(Entity entity)`

Override this method to return a Card subtitle, if desired.

`EliteORMEditorStyle get style`

The default implementation provides an `EliteORMEditorStyle` object containing methods that help determine the appearance of the list screen.

`int sorter(Entity a, Entity b)`

Implements a sorter for use with List.sort() for two database entities.  It uses the `getEntityTitle` to extract the title from both entities and sorts based on those.

`Widget renderEntity(Entity entity)`

Renders a widget to display information about the database entity.

`Widget renderEntities(AsyncSnapshot<List<Entity>> snapshot)`

Renders the list of entities or a "loading" circular progress indicator.

`Row? renderBottomIcons()`

Override this in your child class and return a Row containing a list of  widgets to show a bottom navigation bar.

The default implementation returns a Row with a single "plus" icon to create new database Entity objects.

`Widget? renderBottomNavigationBar()`

This method creates a `BottomAppBar` if `renderBottomIcons()` does not return null.

`PreferredSizeWidget renderAppBar()`

The default implementation returns an AppBar widget with a text title.

`Widget build(BuildContext context)`

The default implementation uses a simple Scaffold.  Override this in your child class if this implementation does not suit your needs.
