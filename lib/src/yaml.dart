import 'package:collection/collection.dart';

class YamlDocument {
   final YamlNode contents;
}

abstract class YamlNode {
}

class YamlMap extends YamlNode with collection.MapMixin, UnmodifiableMapMixin {
}

class YamlList extends YamlNode with collection.ListMixin {
}

List<YamlDocument> loadYamlDocuments(String yaml) {
   return [];
}
