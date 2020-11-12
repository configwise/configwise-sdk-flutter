class ComponentEntity {

  final String id;

  final String parent_id;

  final String genericName;

  final String description;

  final String productNumber;

  final String productLink;

  final bool isFloating;

  final String thumbnailFileKey;

  final int totalSize;

  final bool isVariance;

  ComponentEntity(
      this.id,
      this.parent_id,
      this.genericName,
      this.description,
      this.productNumber,
      this.productLink,
      this.isFloating,
      this.thumbnailFileKey,
      this.totalSize,
      this.isVariance
  );

  static ComponentEntity fromJson(Map<dynamic, dynamic> json) {
    return ComponentEntity(
      json["id"] as String,
      json["parent_id"] as String,
      json["genericName"] as String,
      json["description"] as String,
      json["productNumber"] as String,
      json["productLink"] as String,
      json["isFloating"] as bool,
      json["thumbnailFileKey"] as String,
      json["totalSize"] as int,
      json["isVariance"] as bool,
    );
  }
}
