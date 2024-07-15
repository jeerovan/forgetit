import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:forgetit/globals.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_setting.dart';
import 'package:forgetit/model_tag.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as pimg;
import 'model_item_tag.dart';

bool mobile = Platform.isAndroid;

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
  
  OverlayEntry? entry;
  final FocusNode tagFocusNode = FocusNode();
  final GlobalKey tagTextFieldKey = GlobalKey();
  List<ModelTag> availableTags = [];
  
  int profileId = ModelSetting.getForKey("profile", 1);

  void initData() async {
    tagFocusNode.addListener(() {
      if (tagFocusNode.hasFocus){
        if (itemTagController.text.isNotEmpty){
          if(availableTags.isNotEmpty){
            entry?.remove();
            showOverlay();
          } else {
            hideOverlay();
          }
        } else {
          hideOverlay();
        }
      } else if(availableTags.isEmpty){
        resetSearch();
      }
    });
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
    if (pickedFile != null) {
      var bytes = await File(pickedFile.path).readAsBytes();
      pimg.Image? src = pimg.decodeImage(bytes);
      if(src != null){
        var cropSize = min(src.width, src.height);
        cropSize = cropSize > 1024 ? 1024 : cropSize;
        int offsetX = (src.width - cropSize) ~/ 2;
        int offsetY = (src.height - cropSize) ~/ 2;
        pimg.Image destImage =
          pimg.copyCrop(src, x:offsetX, y:offsetY, width:cropSize, height:cropSize);
        image = Uint8List.fromList(pimg.encodePng(destImage));
      }
      setState(() {
      });
    }
  }
  Future<void> _setImage() async {
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
  void updateAvailableTags(String query) async {
    if (query.isNotEmpty && query.length > 1){
      availableTags = await ModelTag.search(query);
      if(availableTags.isNotEmpty){
        setState(() {
            entry?.remove();
            showOverlay();
        });
      } else {
        hideOverlay();
      }
    } else {
      hideOverlay();
    }
  }
  void showOverlay(){
    final overlay = Overlay.of(context);
    final renderBox = tagTextFieldKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    double overlayHeight = 200;
    entry = OverlayEntry(
      builder: (context) => 
        Positioned(
          left: offset.dx,
          height: overlayHeight,
          top: offset.dy - overlayHeight,
          width: size.width,
          child: 
            Material(
              borderRadius: BorderRadius.circular(10),
              elevation: 8,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 10.0,
                    runSpacing: 10.0,
                    children: availableTags.map((tag) {
                      return GestureDetector(
                        onTap: () => addAvailableTag(tag),
                        child: Chip(
                          label: Text(tag.title),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
        ),
    );
    overlay.insert(entry!);
  }
  void resetSearch(){
    hideOverlay();
    itemTagController.clear();
    availableTags = [];
  }
  void hideOverlay(){
    entry?.remove();
    entry = null;
  }
  void addAvailableTag(ModelTag tag){
    itemChanged = true;
    setState(() {
      checkAddTag(tag);
    });
  }
  void addNewTag() async {
    if(itemTagController.text.isEmpty)return;
    itemChanged = true;
    String tagTitle = itemTagController.text.trim();
    ModelTag tag = ModelTag(title: tagTitle);
    setState(() {
      checkAddTag(tag);
      resetSearch();
    });
  }
  void removeTag(ModelTag tag) async {
    if(item.id != null){
      await ModelItemTag.removeForItemIdTagId(item.id!, tag.id!);
    }
    setState(() {
      tags.remove(tag);
    });
  }
  void checkAddTag(ModelTag newTag){
    bool exist = false;
    for(ModelTag tag in tags){
      if (tag.title == newTag.title){
        exist = true;
        break;
      }
    }
    if(!exist){
      tags.add(newTag);
    }
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
          await ModelItemTag.checkAddItemTag(itemId, tagId,);
        }
      }
    }
    if(mounted)Navigator.of(context).pop();
  }
  void deleteItem(){
    item.delete();
    Navigator.of(context).pop();
  }
  @override
  void initState() {
    super.initState();
    initData();
  }
  @override
  void dispose(){
    hideOverlay();
    itemTitleController.dispose();
    itemTagController.dispose();
    tagFocusNode.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        title: const Text("Add/Edit Item"),
        actions: [
          if (widget.itemId > 0) IconButton(onPressed: deleteItem, icon: const Icon(Icons.delete,color: Colors.red,))
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () async {
                      if(mobile){
                        await _takePicture();
                      } else {
                        _setImage();
                      }
                    },
                    child: SizedBox(
                      width: 150,
                      height: 150,
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
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Wrap(
                      spacing: 10.0,
                      runSpacing: 10.0,
                      children: tags.map((tag) {
                        return GestureDetector(
                          onTap: () => removeTag(tag),
                          child: Chip(
                            label: Text(tag.title),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  color: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.check),
                  onPressed: () {
                    saveItem();
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TextField(
                      key: tagTextFieldKey,
                      controller: itemTagController,
                      focusNode: tagFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Add a tag',
                        suffixIcon: IconButton(
                              icon: const Icon(Icons.publish,),
                              color: Theme.of(context).colorScheme.primary,
                              onPressed: (){
                                addNewTag();
                              },
                            ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16.0),
                      ),
                      onChanged: (value) {
                        updateAvailableTags(value);
                      },
                    ),
                  ),
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