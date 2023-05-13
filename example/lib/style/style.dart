import 'package:elite_orm_editor/elite_orm_editor.dart';

class Style extends EliteORMEditorStyle {
  static final Style _singleton = Style._internal();

  factory Style() {
    return _singleton;
  }

  Style._internal();
}
