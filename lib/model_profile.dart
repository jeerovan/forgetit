import 'dart:typed_data';


import 'database_helper.dart';

class ModelProfile {
  int? id;
  String title;
  Uint8List image;
  ModelProfile({
    this.id,
    required this.title,
    required this.image,
  });
  factory ModelProfile.init(){
    return ModelProfile(
      id:null,
      title:"",
      image: Uint8List(0)
    );
  }
  Map<String,dynamic> toMap() {
    return  {
      'id':id,
      'title':title,
      'image':image
    };
  }
  static Future<ModelProfile> fromMap(Map<String,dynamic> map) async {
    return ModelProfile(
      id:map.containsKey('id') ? map['id'] : null,
      title:map.containsKey('title') ? map['title'] : "",
      image: map.containsKey('image') ? map['image'] : Uint8List(0),
    );
  }
  static Future<List<ModelProfile>> all() async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      "profile",
    );
    return await Future.wait(rows.map((map) => fromMap(map)));
  }
  static Future<ModelProfile?> get(int id) async{
    final dbHelper = DatabaseHelper.instance;
    List<Map<String,dynamic>> list = await dbHelper.queryOne("profile", id);
    if (list.isNotEmpty) {
      Map<String,dynamic> map = list.first;
      return fromMap(map);
    }
    return null;
  }
  Future<int> insert() async{
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.insert("profile", toMap());
  }
  Future<int> update() async{
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.update("profile",toMap(),id);
  }
  Future<int> delete() async {
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.delete("profile", id);
  }
}