import 'dart:typed_data';
import 'package:elite_orm/elite_orm.dart';
import 'package:flutter/material.dart';

class GarbageDisposal extends Entity<GarbageDisposal> {
  /// This is our model representative of a garbage disposal.
  GarbageDisposal([brand = "", model = "", horsePower = 0.5])
      : super(GarbageDisposal.new) {
    members.add(DBMember<String>("brand", brand));
    members.add(DBMember<String>("model", model, true));
    members.add(DBMember<double>("horsePower", horsePower));
  }

  /// The brand of the garbage disposal.
  String get brand => members[0].value;

  /// The model of the garbage disposal.
  String get model => members[1].value;

  /// The horse power of the garbage disposal.
  double get horsePower => members[2].value;

  /// Used by EliteORMEditor when this object is displayed in a list.
  @override
  String toString() {
    return "$brand - $model";
  }
}

/// An example of how to write a class that implements Serializable.
class DBColor extends Color with Serializable {
  /// A database representation of flutter's Color class
  DBColor([int value = 0]) : super(value);

  /// Construct an object given the values stored within the database map.
  @override
  Future fromJson(DatabaseMap map) async {
    return DBColor(map["color"]);
  }

  /// Convert an object into a map of name/value pairs.
  @override
  DatabaseMap toJson() {
    return {"color": value};
  }
}

enum MountStyle { dropIn, underMount, farmHouse }

class KitchenSink extends Entity<KitchenSink> {
  /// The objective is to use every type available to elite_orm.
  KitchenSink([
    type = "",
    bays = 1,
    sprayerHoseLength = 95.0,
    mount = MountStyle.dropIn,
    bool instant = false,
    Uint8List? image,
    DateTime? installed,
    Duration? fillTime,
    bayDepth = const <double>[],
    List<GarbageDisposal> disposals = const [],
    Color color = Colors.black,
  ]) : super(KitchenSink.new) {
    // Because this member is first, it is the primary key.
    members.add(DBMember<String>("type", type));
    members.add(DBMember<int>("bays", bays));
    members.add(DBMember<double>("sprayerHoseLength", sprayerHoseLength));
    members.add(EnumDBMember(MountStyle.values, "mountStyle", mount));
    members.add(BoolDBMember("instantHotWater", instant));
    members.add(BinaryDBMember("image", image ?? Uint8List(0)));
    members.add(DateTimeDBMember("installed", installed ?? DateTime.now()));
    members.add(DurationDBMember("fillTime", fillTime ?? const Duration()));
    members.add(PrimitiveListDBMember<double>("bayDepth", bayDepth));
    members.add(ListDBMember<GarbageDisposal>(
        GarbageDisposal.new, "disposals", disposals));
    members.add(
        ObjectDBMember<DBColor>(DBColor.new, "color", DBColor(color.value)));
  }

  String get type => members[0].value;
  int get bays => members[1].value;
  Uint8List get image => members[5].value;
}
