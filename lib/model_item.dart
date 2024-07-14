import 'dart:typed_data';

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
  static Future<ModelItem?> getLastAdded() async{
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "item",
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