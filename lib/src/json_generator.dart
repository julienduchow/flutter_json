// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import '../annotations.dart';

class JsonGenerator extends GeneratorForAnnotation<json> {
  const JsonGenerator();

  @override
  generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    MetaClass metaClass = generateMetaData(element);
    StringBuffer stringBuffer = StringBuffer();

    generateHead(metaClass, stringBuffer);
    generateToJson(metaClass, stringBuffer);
    generateFromJson(metaClass, stringBuffer);
    generateFooter(metaClass, stringBuffer);

    return stringBuffer.toString();
  }

  void generateHead(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("");
    stringBuffer.writeln("// JSON class for " + metaClass.className + " serving basic methods for serialize and deserialize " + metaClass.className + ".");
    stringBuffer.writeln("");
    stringBuffer.writeln("class " + metaClass.className + "Json extends JsonAble<" + metaClass.className + "> {");
    stringBuffer.writeln("");
  }

  void generateToJson(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("Map<String, dynamic> toJson (" + metaClass.className + " " + metaClass.instanceName + ") {");
    stringBuffer.writeln("Map<String, dynamic> map = Map();");
    stringBuffer.write("map['type'] = '" + metaClass.className + "';");
    metaClass.listFields!.forEach((metaField) {
      stringBuffer.writeln("if(" + metaClass.instanceName + "." + metaField.fieldName + " != null) {");
      String content;
      if (metaField.jsonType!.listTypeType != null) {
        content = metaClass.instanceName + "." + metaField.fieldName + "!.map((data1) => " + doMappingTo(metaField.jsonType!.listTypeType!, 1) + ").toList();";
        //content = 'List<' + metaField.jsonType.referenceClassName + '>.from(map[\"' + metaField.jsonType.referenceClassName + "\"].map((data) => data).toList())";
        //content = metaField.jsonType.convertToJsonPre + metaClass.instanceName + "." + metaField.fieldName + metaField.jsonType.convertToJsonPost;database
      } else {
        content = metaField.jsonType!.convertToJsonPre + metaClass.instanceName + "." + metaField.fieldName + metaField.jsonType!.convertToJsonPost;
        if (metaField.jsonType!.referenceClassName != null) {
          content = metaField.jsonType!.referenceClassName! + "Json().toJson(" + content + "!)";
        }
      }

      stringBuffer.write("map[\"" + metaField.jsonName + "\"] = " + content + ";");
      stringBuffer.writeln("}");
    });
    stringBuffer.writeln("return map;");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  //map["listMatchInformations"] = combinedUpdateData.listMatchInformations.map((e) => MatchInformationJson().toJson(e));

  void generateFromJson(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln(metaClass.className + " fromJson(Map<String, dynamic> map) {");
    stringBuffer.writeln(metaClass.className + " " + metaClass.instanceName + " = " + metaClass.className + "();");
    metaClass.listFields!.forEach((metaField) {
      stringBuffer.writeln("if (map[\"" + metaField.jsonName + "\"] != null) {");
      String content;
      if (metaField.jsonType!.listTypeType != null) {
        content = 'List<' +
            metaField.jsonType!.referenceClassName! +
            '>.from(map[\"' +
            metaField.jsonName +
            "\"].map((data1) => " +
            doMappingFrom(metaField.jsonType!.listTypeType!, 1) +
            ").toList())";
        //content = 'List<' + metaField.jsonType.referenceClassName + '>.from(map[\"' + metaField.jsonType.referenceClassName + "\"].map((data) => data).toList())";
        //content = metaField.jsonType.convertToObjectPre + "map[\"" + metaField.jsonName + "\"]" + metaField.jsonType.convertToObjectPost;
      } else {
        content = metaField.jsonType!.convertToObjectPre + "map[\"" + metaField.jsonName + "\"]" + metaField.jsonType!.convertToObjectPost;
        if (metaField.jsonType!.referenceClassName != null) {
          content = metaField.jsonType!.referenceClassName! + "Json().fromJson(" + content + ")";
        }
      }
      stringBuffer.write(metaClass.instanceName + "." + metaField.fieldName + " = " + content + ";");
      stringBuffer.writeln("}");
    });
    stringBuffer.writeln("return " + metaClass.instanceName + ";");
    stringBuffer.writeln("}");
    stringBuffer.writeln("");
  }

  String doMappingFrom(JsonType jsonType, int c) {
    if (jsonType.listTypeType != null) {
      return "List<" +
          jsonType.referenceClassName! +
          ">.from(data" +
          c.toString() +
          ".map((data" +
          (c + 1).toString() +
          ") => " +
          doMappingFrom(jsonType.listTypeType!, c + 1) +
          ").toList())";
      //} else if(isPrimaryType(jsonType.referenceClassName)) {
    } else if (jsonType.referenceClassName == null || isPrimaryType(jsonType.referenceClassName!)) {
      return 'data' + c.toString();
    } else {
      return jsonType.referenceClassName! + "Json().fromJson(data" + c.toString() + ")";
    }
  }

  String doMappingTo(JsonType jsonType, int c) {
    if (jsonType.listTypeType != null) {
      return "data" + c.toString() + ".map((data" + (c + 1).toString() + ") => " + doMappingTo(jsonType.listTypeType!, c + 1) + ").toList()";
      //} else if(isPrimaryType(jsonType.referenceClassName)) {
    } else if (jsonType.referenceClassName == null || isPrimaryType(jsonType.referenceClassName!)) {
      return 'data' + c.toString();
    } else {
      return jsonType.referenceClassName! + "Json().toJson(data" + c.toString() + ")";
    }
  }

  // combinedUpdateData.listMatchInformations = List<MatchInformation>.from(map["listMatchInformations"].map((data) => MatchInformationJson().fromJson(data)).toList());

  bool isPrimaryType(String type) => type == 'int' || type == 'bool' || type == 'double' || type == 'String';

  void generateFooter(MetaClass metaClass, StringBuffer stringBuffer) {
    stringBuffer.writeln("}");
  }

  // Helper Methods

  MetaClass generateMetaData(Element element) {
    MetaClass metaClass = MetaClass(className: element.displayName, instanceName: element.displayName.substring(0, 1).toLowerCase() + element.displayName.substring(1),
        jsonName: element.displayName);
    if (element.metadata[0].computeConstantValue()!.getField("genericMappings") != null &&
        element.metadata[0].computeConstantValue()!.getField("genericMappings")!.toMapValue() != null) {
      metaClass.genericMappings =
          element.metadata[0].computeConstantValue()!.getField("genericMappings")!.toMapValue()!.map((key, value) => MapEntry(key!.toStringValue(), value!.toStringValue()));
    }
    metaClass.listFields = getFieldsWithSuper(element as ClassElement, metaClass);
    return metaClass;
  }

  List<MetaField> getFieldsWithSuper(ClassElement clazz, MetaClass metaClass) {
    List<MetaField> listFields = [];
    if (clazz.supertype != null && clazz.supertype.toString() != 'Object') {
      listFields.addAll(getFieldsWithSuper(clazz.supertype!.element as ClassElement, metaClass));
    }

    clazz.typeParameters.forEach((element) {
      //print(element);
    });
    clazz.typeParameters.forEach((element) {
      //print(element.bound.toString());
    });
    clazz.typeParameters.forEach((element) {
      //print(element.displayName.toString());
    });
    clazz.typeParameters.forEach((element) {
      //print(element.name.toString());
    });
    clazz.fields.forEach((field) {
      bool ignore = false;

      field.metadata.forEach((element) {
        if (element.element.toString() == "id id()" || element.element.toString() == "jsonIgnore jsonIgnore()") {
          ignore = true;
        }
      });

      /*field.metadata.forEach((element) {
        if (element.element.toString().startsWith("JsonIgnore")) {
          ignore = true;
        }
      });*/

      if (!ignore) {
        MetaField metaField = MetaField(fieldName: field.displayName, fieldType: field.type.toString(), jsonName: field.displayName);
        metaField.jsonType = getJsonTypeForDartType(field.type.toString(), metaClass, field);
        /*if(metaClass.className == 'X01GameProcessor') {
        //print(field.type.element.displayName);
        //print(field.type.element.runtimeType.toString());
        //print(field.runtimeType.toString());
        //print(field.type.element.hasOptionalTypeArgs);
        field.type.element.metadata.forEach((element) {//print(element.toString());});
      }*/
        if (metaField.fieldName != 'hashCode' && metaField.fieldName != 'runtimeType') {
          listFields.add(metaField);
        }
      }
    });
    return listFields;
  }

  JsonType getJsonTypeForDartType(String dartType, MetaClass metaClass, FieldElement? field) {
    ////print(dartType);
    if (dartType.toString().startsWith("List<")) {
      String refClassName = dartType.toString().substring(dartType.toString().indexOf("<") + 1, dartType.toString().lastIndexOf(">")).replaceAll("?", "");

      if (metaClass.genericMappings != null) {
        metaClass.genericMappings!.forEach((key, value) {
          //print(key.toString());
          //print(value.toString());
          if (key.toString() == refClassName) refClassName = value.toString();
        });
      }

      return JsonType(
          listTypeType: getJsonTypeForDartType(dartType.toString().substring(dartType.toString().indexOf("<") + 1, dartType.toString().indexOf(">") + 1), metaClass, null),
          referenceClassName: refClassName);
    }
    if (dartType.toString() == "int?" || dartType.toString() == "int") {
      return JsonType();
    } else if (dartType.toString() == "double?") {
      return JsonType();
    } else if (dartType.toString() == "String?") {
      return JsonType();
    } else if (dartType.toString() == "bool?") {
      return JsonType(convertToJsonPost: "" /*""" ? \"true\" : \"false\""*/);
    } else if (dartType.toString() == "DateTime?") {
      bool isTime = false;
      bool isDate = false;
      field?.metadata.forEach((element) {
        //print("TTTTTTTTTTTTTTTTTTTTTTT" + element.element.toString());
        if(element.element.toString() == 'onlyTime onlyTime()') isTime = true;
        if(element.element.toString() == 'onlyDate onlyDate()') isDate = true;
      });
      if(isTime) {
        return JsonType(convertToJsonPost: "!.toIso8601String().substring(11,22)", convertToObjectPre: "DateTime.parse(\"1970-01-01T\" + ", convertToObjectPost: ')');
      } else if (isDate) {
        return JsonType(convertToJsonPost: "!.toIso8601String().substring(0,10)", convertToObjectPre: 'DateTime.parse(',convertToObjectPost: "+ \"T00:00:00.000\")");
      } else {
        return JsonType(convertToObjectPre: 'DateTime.parse(', convertToObjectPost: ')', convertToJsonPost: '!.toIso8601String()');
      }
    } else if (dartType.toString() == "Duration?") {
      return JsonType(convertToJsonPost: "!.inMilliseconds", convertToObjectPre: "Duration(milliseconds:(", convertToObjectPost: "))");
    }
    String refName = "";
    if (dartType.toString().contains("<")) {
      refName = dartType.toString().substring(0, dartType.toString().indexOf("<"));
    } else {
      refName = dartType.toString().substring(0, dartType.toString().length - 1);
    }
    if (metaClass.genericMappings != null) {
      metaClass.genericMappings!.forEach((key, value) {
        //print(key.toString());
        //print(value.toString());
        if (key.toString() == refName) refName = value.toString();
      });
    }
    return JsonType(referenceClassName: refName);
  }
}

class MetaClass {
  String className;
  String instanceName;
  String jsonName;
  Map? genericMappings;
  List<MetaField>? listFields;

  MetaClass({required this.className, required this.instanceName, required this.jsonName});

  @override
  String toString() {
    return (className ?? 'null') + "\n" + (instanceName ?? 'null') + "\n" + (jsonName ?? 'null') + "\n[" + (listFields ?? 'null').toString() + "]";
  }
}

class MetaField {
  String fieldName;
  String fieldType;
  String jsonName;
  JsonType? jsonType;

  MetaField({required this.fieldName, required this.fieldType, required this.jsonName});

  String toString() {
    return (fieldName ?? 'null') + "\n" + (fieldType ?? 'null') + "\n" + (jsonName ?? 'null') + "\n" + (jsonType ?? 'null').toString();
  }
}

class JsonType {
  JsonType(
      {this.createExtension = "",
        this.convertToJsonPre = "",
        this.convertToJsonPost = "",
        this.convertToObjectPre = "",
        this.listTypeType = null,
        this.convertToObjectPost = "",
        this.referenceClassName});

  String? referenceClassName;
  String createExtension;
  String convertToJsonPre;
  String convertToJsonPost;
  String convertToObjectPre;
  String convertToObjectPost;
  JsonType? listTypeType;

  String toString() {
    return (referenceClassName ?? 'null') + "\n" + (listTypeType?.toString() ?? "null");
  }
}