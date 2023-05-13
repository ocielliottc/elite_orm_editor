import '../model/kitchen_sink.dart';

/// Return a list of all table descriptions.
List<String> getTableDescriptions() {
  return [
    KitchenSink().describeTable(),
  ];
}
