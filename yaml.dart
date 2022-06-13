import "dart:io";

class YamlParser {
  final String yaml;
  var offset = 0;

  bool get haveData => offset < yaml.length;
  String get nextChar => yaml[offset];

  YamlParser(this.yaml);

  List<Map<dynamic, dynamic>> parse() {
    var documents = <Map<dynamic, dynamic>>[];
    while (haveData) {
      documents.add(parseDocument());
    }

    return documents;
  }

  Map<dynamic, dynamic> parseDocument() {
    if (!yaml.startsWith('---\n', offset)) {
      throw 'Missing start of document';
    }
    offset += 4;

    var document = parseMap(0);

    if (haveData && nextChar == '\n') {
      offset++;
    }

    return document;
  }

  dynamic parseValue({bool allowColon = true}) {
    if (nextChar == "'") {
      return parseSingleQuotedValue();
    } else if (nextChar == '"') {
      return parseDoubleQuotedValue();
    } else if (nextChar == '>') {
      return parseFoldedString();
    } else if (nextChar == '\n') {
      offset++;
      return parseMapOrList();
    } else {
      return parseScalar(allowColon: allowColon);
    }
  }

  String parseSingleQuotedValue() {
    assert(nextChar == "'");
    String value = '';
    while (haveData) {
      offset++;
      if (nextChar == "'") {
        offset++;
        return value;
      }
      value += nextChar;
    }

    throw 'Unterminated single quoted value';
  }

  String parseDoubleQuotedValue() {
    assert(nextChar == '"');
    String value = '';
    while (haveData) {
      offset++;
      if (nextChar == '"') {
        offset++;
        return value;
      }
      value += nextChar;
    }

    throw 'Unterminated double quoted value';
  }

  String parseFoldedString() {
    var start = offset;

    assert(nextChar == '>');
    offset++;
    if (offset >= yaml.length) {
      throw 'Missing content for multi-line string';
    }
    if (nextChar == '-' || nextChar == '+') {
      // FIXME
      offset++;
    }
    skipWhitespace();
    if (nextChar != '\n') {
      throw 'Missing content for multi-line string';
    }
    offset++;

    String value = '';
    var indent = 0;
    while (offset + indent < yaml.length && yaml[offset + indent] == ' ') {
      indent++;
    }
    if (indent == 0) {
      throw 'Missing folded string indentation';
    }

    while (haveData) {
      if (!hasIndent(indent)) {
        break;
      }
      offset += indent;

      var lineStart = offset;
      var lineEnd = offset;
      while (haveData) {
        var c = nextChar;
	offset++;
        if (c != '\n') {
          lineEnd++;
        }
        if (c == '\n') {
          break;
        }
      }

      if (value != '') {
         value += ' ';
      }
      value += yaml.substring(lineStart, lineEnd);
    }

    // Rewind back over last newline
    if (offset > start && yaml[offset - 1] == '\n') {
      offset--;
    }

    return value;
  }

  dynamic parseMapOrList() {
    var indent = 0;
    while (offset + indent < yaml.length && yaml[offset + indent] == ' ') {
      indent++;
    }
    if (indent == 0) {
      throw 'Missing map/list indentation';
    }
    if (offset + indent >= yaml.length) {
      throw 'Missing map/list entry';
    }

    if (yaml[offset + indent] == '-') {
      offset++;
      return parseList(indent);
    }

    return parseMap(indent);
  }

  Map<dynamic, dynamic> parseMap(int indent) {
    var start = offset;
    var map = <String, dynamic>{};
    while (haveData) {
      // Start of next document
      if (yaml.startsWith('---\n', offset)) {
        break;
      }

      if (!hasIndent(indent)) {
        break;
      }
      offset += indent;

      var key = parseValue(allowColon: false);

      if (offset >= yaml.length || nextChar != ':') {
        throw 'Missing colon after key';
      }
      offset++;
      skipWhitespace();

      var value = parseValue();
      skipWhitespace();

      if (haveData) {
        if (nextChar != '\n') {
          throw 'Missing trailing newline after map value';
        }
        offset++;
      }

      map[key] = value;
    }

    // Rewind back over last newline
    if (offset > start && yaml[offset - 1] == '\n') {
      offset--;
    }

    return map;
  }

  bool hasIndent(int indent) {
    if (offset + indent >= yaml.length) {
      return false;
    }
    for (var i = 0; i < indent; i++) {
      if (yaml[offset + i] != ' ') {
        return false;
      }
    }
    return true;
  }

  void skipWhitespace() {
    while (haveData && nextChar == ' ') {
      offset++;
    }
  }

  List<dynamic> parseList(int indent) {
    var start = offset;
    var list = <String>[];
    while (haveData) {
      // Start of next document
      if (yaml.startsWith('---\n', offset)) {
        break;
      }

      if (!hasIndent(indent)) {
        break;
      }
      offset += indent;

      if (offset >= yaml.length || nextChar != '-') {
        throw 'Missing list hyphen';
      }
      offset++;
      skipWhitespace();

      var value = parseValue();
      skipWhitespace();

      if (haveData) {
        if (nextChar != '\n') {
          throw 'Missing trailing newline after map value';
        }
        offset++;
      }

      list.add(value);
    }

    // Rewind back over last newline
    if (offset > start && yaml[offset - 1] == '\n') {
      offset--;
    }

    return list;
  }

  String parseScalar({bool allowColon = true}) {
    var start = offset;
    while (haveData) {
      if (nextChar == '\n') {
        break;
      }
      if (!allowColon && nextChar == ':') {
        break;
      }
      offset++;
    }

    return yaml.substring(start, offset);
  }
}

void main() {
  var yaml = File('components2.yml').readAsStringSync();
  var parser = YamlParser(yaml);
  print(parser.parse());
}
