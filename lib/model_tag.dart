import 'database_helper.dart';
class ModelTag {
  int? id;
  String title;
  ModelTag({
    this.id,
    required this.title,
  });
  factory ModelTag.init(){
    return ModelTag(
      id:null,
      title:"",
    );
  }
  Map<String,dynamic> toMap() {
    return  {
      'id':id,
      'title':title
    };
  }
  static Future<ModelTag> fromMap(Map<String,dynamic> map) async {
    return ModelTag(
      id:map.containsKey('id') ? map['id'] : null,
      title:map.containsKey('title') ? map['title'] : ""
    );
  }
  static Future<List<ModelTag>> search(String query) async {
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;
    List<Map<String,dynamic>> rows = await db.query(
      'tag',
      where: 'title LIKE ?',
      whereArgs: ['%$query%']);
    return await Future.wait(rows.map((map) => fromMap(map)));
  }
  static Future<ModelTag?> get(int id) async{
    final dbHelper = DatabaseHelper.instance;
    List<Map<String,dynamic>> list = await dbHelper.queryOne("tag", id);
    if (list.isNotEmpty) {
      Map<String,dynamic> map = list.first;
      return fromMap(map);
    }
    return null;
  }
  Future<int> insert() async{
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.insert("tag", toMap());
  }
  Future<int> update() async{
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.update("tag",toMap(),id);
  }
  Future<int> delete() async {
    final dbHelper = DatabaseHelper.instance;
    int? id = this.id;
    return await dbHelper.delete("tag", id);
  }
}