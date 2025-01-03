// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class json {
  const json(this.genericMappings);
  final Map<String, String> genericMappings;
}

class onlyDate {
  const onlyDate();
}

class onlyTime {
  const onlyTime();
}

abstract class JsonAble<E> {
  E fromJson(Map<String, dynamic> jsonStr);

  Map<String, dynamic> toJson(E jsonAble);
}

class StringJson {
  String fromJson(json) => json.toString();
  String toJson(string) => string.toString();
}

/*class intJson {
  int fromJson(json) => json;
  int toJson(string) => string;
}

class doubleJson {
  double fromJson(json) => json;
  double toJson(string) => string;
}

class boolJson {
  bool fromJson(json) => json;
  bool toJson(string) => string;
}

class DateTimeJson {
  String fromJson(json) => json.toString();
  String toJson(string) => string.toString();
}

    .toIso8601String()*/