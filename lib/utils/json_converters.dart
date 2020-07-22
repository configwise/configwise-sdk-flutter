import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:vector_math/vector_math_64.dart';

class DoubleValueNotifierConverter extends ValueNotifierConverter<double> {
  const DoubleValueNotifierConverter() : super();
}

class StringValueNotifierConverter extends ValueNotifierConverter<String> {
  const StringValueNotifierConverter() : super();
}

class BoolValueNotifierConverter extends ValueNotifierConverter<bool> {
  const BoolValueNotifierConverter() : super();
}

class IntValueNotifierConverter extends ValueNotifierConverter<int> {
  const IntValueNotifierConverter() : super();
}

class ValueNotifierConverter<T> implements JsonConverter<ValueNotifier<T>, T> {
  const ValueNotifierConverter();

  @override
  ValueNotifier<T> fromJson(T json) => ValueNotifier<T>(json);

  @override
  T toJson(ValueNotifier<T> object) => object?.value;
}

class MatrixConverter implements JsonConverter<Matrix4, List<dynamic>> {
  const MatrixConverter();

  @override
  Matrix4 fromJson(List<dynamic> json) {
    return Matrix4.fromList(json.cast<double>());
  }

  @override
  List<dynamic> toJson(Matrix4 matrix) {
    final list = List<double>(16);
    matrix.copyIntoArray(list);
    return list;
  }
}

class MapOfMatrixConverter
    implements
        JsonConverter<Map<String, Matrix4>, Map<dynamic, List<dynamic>>> {
  const MapOfMatrixConverter();

  @override
  Map<String, Matrix4> fromJson(Map<dynamic, List<dynamic>> json) {
    const converter = MatrixConverter();
    return Map<String, List<dynamic>>.from(json)
        .map((k, v) => MapEntry(k, converter.fromJson(v)));
  }

  @override
  Map<dynamic, List<dynamic>> toJson(Map<String, Matrix4> matrix) {
    const converter = MatrixConverter();
    return matrix.map((k, v) => MapEntry(k, converter.toJson(v)));
  }
}

class Vector2Converter implements JsonConverter<Vector2, List<dynamic>> {
  const Vector2Converter();

  @override
  Vector2 fromJson(List<dynamic> json) {
    return Vector2(json[0], json[1]);
  }

  @override
  List<double> toJson(Vector2 object) {
    final list = List<double>(2);
    object.copyIntoArray(list);
    return list;
  }
}

class Vector3Converter implements JsonConverter<Vector3, List<dynamic>> {
  const Vector3Converter();

  @override
  Vector3 fromJson(List<dynamic> json) {
    return Vector3(json[0], json[1], json[2]);
  }

  @override
  List<dynamic> toJson(Vector3 object) {
    final list = List<double>(3);
    object.copyIntoArray(list);
    return list;
  }
}

class Vector4Converter implements JsonConverter<Vector4, List<dynamic>> {
  const Vector4Converter();

  @override
  Vector4 fromJson(List<dynamic> json) {
    return Vector4(json[0], json[1], json[2], json[3]);
  }

  @override
  List<dynamic> toJson(Vector4 object) {
    final list = List<double>(4);
    object.copyIntoArray(list);
    return list;
  }
}

class Vector3ValueNotifierConverter
    implements JsonConverter<ValueNotifier<Vector3>, List<dynamic>> {
  const Vector3ValueNotifierConverter();

  @override
  ValueNotifier<Vector3> fromJson(List<dynamic> json) {
    return ValueNotifier(Vector3.fromFloat64List(json.cast<double>()));
  }

  @override
  List<dynamic> toJson(ValueNotifier<Vector3> object) {
    if (object == null || object.value == null) {
      return null;
    }
    final list = List<double>(3);
    object?.value?.copyIntoArray(list);
    return list;
  }
}

class Vector4ValueNotifierConverter
    implements JsonConverter<ValueNotifier<Vector4>, List<dynamic>> {
  const Vector4ValueNotifierConverter();

  @override
  ValueNotifier<Vector4> fromJson(List<dynamic> json) {
    return ValueNotifier(Vector4.fromFloat64List(json.cast<double>()));
  }

  @override
  List<dynamic> toJson(ValueNotifier<Vector4> object) {
    if (object == null || object.value == null) {
      return null;
    }
    final list = List<double>(4);
    object?.value?.copyIntoArray(list);
    return list;
  }
}

class MatrixValueNotifierConverter
    implements JsonConverter<ValueNotifier<Matrix4>, List<dynamic>> {
  const MatrixValueNotifierConverter();

  @override
  ValueNotifier<Matrix4> fromJson(List<dynamic> json) {
    return ValueNotifier(Matrix4.fromList(json.cast<double>()));
  }

  @override
  List<dynamic> toJson(ValueNotifier<Matrix4> matrix) {
    if (matrix == null || matrix.value == null) {
      return null;
    }
    final list = List<double>(16);
    matrix.value.copyIntoArray(list);
    return list;
  }
}
