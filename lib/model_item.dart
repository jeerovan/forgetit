
import 'package:flutter/foundation.dart';

import 'database_helper.dart';
import 'model_profile.dart';

class ModelItem {
  int? id;
  int profileId;
  ModelProfile? profile;
  String title;
  Uint8List image;
  ModelItem({
    this.id,
    required this.profileId,
    this.profile,
    required this.title,
    required this.image,
  });
  factory ModelItem.init(){
    return ModelItem(
      id:null,
      profileId:0,
      profile:null,
      title:"",
      image:Uint8List(0)
    );
  }
  Map<String,dynamic> toMap() {
    return  {
      'id':id,
      'profile_id':profileId,
      'title':title,
      'image':image
    };
  }
  static Future<ModelItem> fromMap(Map<String,dynamic> map) async {
    ModelProfile? profile = await ModelProfile.get(map['profile_id']);
    return ModelItem(
      id:map.containsKey('id') ? map['id'] : null,
      profileId:map.containsKey('profile_id') ? map['profile_id'] : 0,
      profile:profile,
      title:map.containsKey('title') ? map['title'] : "",
      image:map.containsKey('image') ? map['image'] : "",
    );
  }
  static Future<List<ModelItem>> getAll(int profileId) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "item",
      where: "profile_id == ?",
      whereArgs: [profileId],
      orderBy:'id DESC',
    );
    return await Future.wait(rows.map((map) => fromMap(map)));
  }
  static Future<List<ModelItem>> getForTag(String tag,int profileId) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    String sql = '''
      SELECT DISTINCT item.*
      FROM item
      INNER JOIN itemtag ON itemtag.item_id == item.id
      INNER JOIN tag ON tag.id == itemtag.tag_id
      WHERE item.profile_id == ?
        AND tag.title LIKE ?
    ''';
    List<Map<String,dynamic>> rows = await db.rawQuery(sql,[profileId,'%$tag%']);
    return await Future.wait(rows.map((map) => fromMap(map)));
  }
  static Future<ModelItem?> getLastAdded(int profileId) async{
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "item",
      where: "profile_id == ?",
      whereArgs: [profileId],
      orderBy:'id DESC',
      limit: 1,
    );
    if (rows.isNotEmpty) {
      Map<String,dynamic> map = rows.first;
      return fromMap(map);
    }
    return null;
  }
  
  static Future<ModelItem?> get(int id) async{
    final dbHelper = DatabaseHelper.instance;
    List<Map<String,dynamic>> list = await dbHelper.queryOne("item", id);
    if (list.isNotEmpty) {
      Map<String,dynamic> map = list.first;
      return fromMap(map);
    }
    return null;
  }
  Future<int> insert() async{
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.insert("item", toMap());
  }
  Future<int> update() async{
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.update("item",toMap(),id);
  }
  Future<int> delete() async {
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.delete("item", id);
  }
}