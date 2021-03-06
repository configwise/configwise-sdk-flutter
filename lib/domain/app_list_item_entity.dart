class AppListItemEntity {

  final String id;

  final String parent_id;

  final String component_id;

  final String type;

  final String label;

  final String description;

  final String imageFileKey;

  final int index;

  final String textColor;

  AppListItemEntity(
      this.id,
      this.parent_id,
      this.component_id,
      this.type,
      this.label,
      this.description,
      this.imageFileKey,
      this.index,
      this.textColor
      );

  static AppListItemEntity fromJson(Map<dynamic, dynamic> json) {
    return AppListItemEntity(
      json["id"] as String,
      json["parent_id"] as String,
      json["component_id"] as String,
      json["type"] as String,
      json["label"] as String,
      json["description"] as String,
      json["imageFileKey"] as String,
      json["index"] as int,
      json["textColor"] as String,
    );
  }
}
