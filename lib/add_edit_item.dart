import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forgetit/globals.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_setting.dart';
import 'package:forgetit/model_tag.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as pimg;
import 'model_item_tag.dart';

class AddEditItem extends StatefulWidget {
  final int itemId;
  const AddEditItem({super.key,required this.itemId});

  @override
  AddEditItemState createState() => AddEditItemState();
}

class AddEditItemState extends State<AddEditItem> {
  final TextEditingController itemTitleController = TextEditingController();
  final TextEditingController itemTagController = TextEditingController();
  ModelItem item = ModelItem.init();
  List<ModelTag> tags = [];
  String? imagePath;
  Uint8List? image;
  bool itemChanged = false;
  int profileId = ModelSetting.getForKey("profile", 1);

  void initData() async {
    ModelItem? existingItem = await ModelItem.get(widget.itemId);
    if(existingItem != null){
      item = existingItem;
      itemTitleController.text = item.title;
      image = item.image;
      tags = await ModelItemTag.getTagsForItemId(widget.itemId);
      setState(() {});
    }
  }
  Future<void> _takePicture() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    String? tempPath;
    if (pickedFile != null) {
      tempPath = pickedFile.path;
      var bytes = await File(tempPath).readAsBytes();
      pimg.Image? src = pimg.decodeImage(bytes);
      if(src != null){
        var cropSize = min(src.width, src.height);
        cropSize = cropSize > 1024 ? 1024 : cropSize;
        int offsetX = (src.width - cropSize) ~/ 2;
        int offsetY = (src.height - cropSize) ~/ 2;
        pimg.Image destImage =
          pimg.copyCrop(src, x:offsetX, y:offsetY, width:cropSize, height:cropSize);
        File(tempPath).writeAsBytesSync(pimg.encodePng(destImage));
      }
      setState(() {
        imagePath = tempPath;
      });
    }
  }
  Future<void> setImage() async {
    int width = 1024;
    int height = 1024;
    final pimg.Image blankImage = pimg.Image(width:width,height: height);
    int r = getRandomInt(256);
    int g = getRandomInt(256);
    int b = getRandomInt(256);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        blankImage.setPixel(x, y, pimg.ColorUint8.rgb(r,g,b));
      }
    }
    image = Uint8List.fromList(pimg.encodePng(blankImage));
    setState(() {
      
    });
  }
  void addTag() async {
    itemChanged = true;
    String tagTitle = itemTagController.text;
    ModelTag tag = ModelTag(title: tagTitle);
    setState(() {
      tags.add(tag);
      itemTagController.clear();
    });
  }
  void saveItem() async {
    if(itemChanged){
      String itemTitle = itemTitleController.text;
      if(itemTitle.isEmpty || image == null){
        showAlertMessage(context, "Alert", "Please add image and some helpful text");
      } else {
        int? itemId = item.id;
        if(itemId == null){
          // add new item
          itemId = await ModelItem(profileId: profileId, title: itemTitle,image: image!).insert();
        } else {
          // update item
          item.title = itemTitle;
          item.image = image!;
          int _ = await item.update();
        }
        for(ModelTag tag in tags){
          int? tagId = tag.id;
          tagId ??= await tag.insert();
          tag.id = tagId;
          await ModelItemTag.checkAddItemTag(itemId, tagId);
        }
      }
    }
    if(mounted)Navigator.of(context).pop();
  }
  @override
  void initState() {
    super.initState();
    initData();
  }
  @override
  void dispose(){
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Add/Edit Item"),
      ),
      body: Column(
        children: [
          GestureDetector(
            onTap: () async { await setImage();},
            child: SizedBox(
              width: 200,
              height: 200,
              child: Card(
                child: Center(
                  child: image != null
                        ? Image.memory(image!)
                        : const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("Tap to take a picutre with surroundings to locate it easily"),
                        ),
                  
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: itemTitleController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Directions to locate', // Placeholder
              ),
              onChanged: (value) {
                itemChanged = true;
              },
            ),
          ),
          Expanded(child: ListView(children: tagsView(tags),),),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemTagController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Add Tags', // Placeholder
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(2.0),
                        child: IconButton(
                          onPressed: (){
                            addTag();
                          },
                          icon: const Icon(Icons.publish,),
                        ),
                      ),
                    ),
                  ),
                ), 
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.small(
                  heroTag: "cancel",
                  onPressed: (){
                    Navigator.of(context).pop();
                  },
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.clear,color: Colors.grey,),
                ),
                const SizedBox(width: 25,),
                FloatingActionButton(
                  heroTag: "submit",
                  onPressed: (){
                    saveItem();
                  },
                  shape: const CircleBorder(),
                  child: const Icon(Icons.check),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  List<Widget> tagsView(List<ModelTag> tags){
    return tags.map((e) => ListTile(title:Text(e.title),onTap: () {
      
    },)).toList();
  }
}