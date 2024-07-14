import 'dart:async';

import 'database_helper.dart';
import 'model_item.dart';
import 'model_tag.dart';
class ModelItemTag {
  int? id;
  int itemId;
  ModelItem? item;
  int tagId;
  ModelTag? tag;
  ModelItemTag({
    this.id,
    required this.itemId,
    this.item,
    required this.tagId,
    this.tag,
  });
  factory ModelItemTag.init(){
    return ModelItemTag(
      id:null,
      itemId:0,
      item:null,
      tagId:0,
      tag:null,
    );
  }
  Map<String,dynamic> toMap() {
    return  {
      'id':id,
      'item_id':itemId,
      'tag_id':tagId
    };
  }
  static Future<ModelItemTag> fromMap(Map<String,dynamic> map) async {
    ModelItem? item = await ModelItem.get(map['item_id']);
    ModelTag? tag = await ModelTag.get(map['tag_id']);
    return ModelItemTag(
      id:map.containsKey('id') ? map['id'] : null,
      itemId:map.containsKey('item_id') ? map['item_id'] : 0,
      item:item,
      tagId:map.containsKey('tag_id') ? map['tag_id'] : 0,
      tag:tag
    );
  }
  static Future<ModelTag> tagFromMap(Map<String,dynamic> map) async {
    ModelTag? tag = await ModelTag.get(map['tag_id']);
    if(tag != null){
      return ModelTag(id: tag.id,title: tag.title);
    } else {
      return ModelTag.init();
    }
  }
  static Future<List<ModelTag>> getTagsForItemId(int itemId) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "itemtag",
      where:'item_id == ?',
      whereArgs: [itemId],
    );
    return await Future.wait(rows.map((map) => tagFromMap(map)));
  }
  static Future<ModelItemTag?> get(int id) async{
    final dbHelper = DatabaseHelper.instance;
    List<Map<String,dynamic>> list = await dbHelper.queryOne("itemtag", id);
    if (list.isNotEmpty) {
      Map<String,dynamic> map = list.first;
      return fromMap(map);
    }
    return null;
  }
  static Future<void> checkAddItemTag(int itemId,int tagId) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "itemtag",
      where:'item_id == ? AND tag_id == ?',
      whereArgs: [itemId,tagId],
    );
    if (rows.isEmpty){
      int _ = await ModelItemTag(itemId: itemId, tagId: tagId).insert();
    }
  }
  Future<int> insert() async{
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.insert("itemtag", toMap());
  }
  Future<int> update() async{
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.update("itemtag",toMap(),id);
  }
  Future<int> delete() async {
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.delete("itemtag", id);
  }
}