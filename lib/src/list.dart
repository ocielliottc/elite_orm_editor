import 'package:flutter/material.dart';
import 'package:elite_orm/elite_orm.dart';

import 'style.dart';

/// Derive your stateful widget class from EliteORMList instead of
/// StatefulWidget.  It will perform the same functionality but will return
/// a specialized State object specific to this list.
abstract class EliteORMList extends StatefulWidget {
  /// Simple constructor that calls the super class.
  const EliteORMList({super.key});
}

/// Derive your state class from EliteORMListState instead of State.  It will
/// provide the same functionality and a default implementation of the `build`
/// method that will display the contents of the `bloc` class as a list of
/// cards that can be tapped in order to edit them.
abstract class EliteORMListState<T extends EliteORMList> extends State<T> {
  /// Provide the bloc for your database entities.
  Bloc get bloc;

  /// Return the title of the screen.
  String get title;

  /// Return a string to indicate to the user that the data is loading.
  String get loading => "Loading...";

  /// Return a widget that will create an "editing" screen when the individual
  /// card is tapped.
  Widget getEditor([Entity? entity]);

  /// Return a Card title that can be extracted from the database entity.
  String getEntityTitle(Entity entity);

  /// Return a Card subtitle that can be extracted from the database entity.
  String? getEntitySubtitle(Entity entity) => null;

  /// Return a style object for use with the layout of the Card list.
  EliteORMEditorStyle get style => EliteORMEditorStyle();

  /// Implement a sorter for use with List.sort() for two database entities.
  /// This will determine the order in which the entities are listed on the
  /// screen.
  int sorter(Entity a, Entity b) =>
      getEntityTitle(a).compareTo(getEntityTitle(b));

  /// Render a widget to display information about the database entity.
  /// You can override this if the default implementation does not suit your
  /// needs.
  Widget renderEntity(Entity entity) {
    final String? subtitle = getEntitySubtitle(entity);
    return GestureDetector(
      child: Card(
        shape: style.cardShape(context),
        child: ListTile(
          subtitle: subtitle == null ? null : Text(subtitle),
          title: Text(getEntityTitle(entity), style: style.cardTitleText),
        ),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => getEditor(entity)),
      ),
    );
  }

  /// Renders the list of entities or a "loading" circular progress indicator.
  /// You can override this if the default implementation does not suit your
  /// needs.
  Widget renderEntities(AsyncSnapshot<List<Entity>> snapshot) {
    if (snapshot.hasData) {
      // Sort the list before giving it to the builder.
      snapshot.data!.sort(sorter);
      return ListView.builder(
        itemCount: snapshot.data!.length,
        itemBuilder: (context, index) => renderEntity(snapshot.data![index]),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            Text(loading, style: style.titleText)
          ],
        ),
      );
    }
  }

  /// Override this in your child class and return a Row containing a list of
  /// widgets to show a bottom navigation bar.
  Row? renderBottomIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.add, color: Theme.of(context).colorScheme.primary),
          iconSize: style.iconSize,
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => getEditor()),
          ),
        ),
      ],
    );
  }

  /// Override this in your child class if this implementation does not suit
  /// your needs.
  Widget? renderBottomNavigationBar() {
    final Row? row = renderBottomIcons();
    return row == null
        ? null
        : BottomAppBar(
            child: Container(
              padding: style.bottomBarPadding,
              decoration: style.bottomBarDecoration(context),
              child: row,
            ),
          );
  }

  /// Called when this object is inserted into the tree.
  @override
  void initState() {
    super.initState();

    // Ensure that the bloc stream is filled.
    bloc.get();
  }

  /// By default, return an AppBar widget with a text title.
  PreferredSizeWidget renderAppBar() => AppBar(title: Text(title));

  /// The default implementation uses a simple Scaffold.  Override this in your
  /// child class if this implementation does not suit your needs.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: SafeArea(
        child: StreamBuilder(
          stream: bloc.all,
          builder: (context, snapshot) => renderEntities(snapshot),
        ),
      ),
      bottomNavigationBar: renderBottomNavigationBar(),
    );
  }
}
