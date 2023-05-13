import 'package:flutter/material.dart';
import 'package:elite_orm/elite_orm.dart';
import 'package:elite_orm_editor/elite_orm_editor.dart';

import '../model/kitchen_sink.dart';
import '../screens/edit.dart';
import '../style/style.dart';

class ListKitchenSinks extends EliteORMList {
  const ListKitchenSinks({super.key});

  @override
  State<ListKitchenSinks> createState() => _ListKitchenSinksState();
}

class _ListKitchenSinksState extends EliteORMListState<ListKitchenSinks> {
  @override
  Bloc get bloc => kitchenSinkBloc;

  @override
  String get title => "Kitchen Sinks";

  @override
  Widget getEditor([Entity? entity]) => EditKitchenSink(
      kitchenSink: entity == null ? null : entity as KitchenSink);

  @override
  String getEntityTitle(Entity entity) => (entity as KitchenSink).type;

  @override
  String getEntitySubtitle(Entity entity) {
    final int bays = (entity as KitchenSink).bays;
    return bays == 1 ? "$bays bay" : "$bays bays";
  }

  @override
  EliteORMEditorStyle get style => Style();

  @override
  int sorter(Entity a, Entity b) {
    final KitchenSink left = a as KitchenSink;
    final KitchenSink right = b as KitchenSink;
    final int cmp = left.type.compareTo(right.type);
    return cmp == 0 ? left.bays.compareTo(right.bays) : cmp;
  }
}
