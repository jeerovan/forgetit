import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:forgetit/globals.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_setting.dart';
import 'package:forgetit/model_tag.dart';
import 'package:image_picker/image_picker.dart';
import 'model_item_tag.dart';

bool mobile = Platform.isAndroid;

class AddEditItem extends StatefulWidget {
  final int itemId;
  const AddEditItem({super.key, required this.itemId});

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
  bool processing = false;

  bool itemChanged = false;

  OverlayEntry? entry;
  final FocusNode tagFocusNode = FocusNode();
  final GlobalKey tagTextFieldKey = GlobalKey();
  List<ModelTag> availableTags = [];

  int profileId = ModelSetting.getForKey("profile", 1);

  void initData() async {
    tagFocusNode.addListener(() {
      if (tagFocusNode.hasFocus) {
        if (itemTagController.text.isNotEmpty) {
          if (availableTags.isNotEmpty) {
            entry?.remove();
            showOverlay();
          } else {
            hideOverlay();
          }
        } else {
          hideOverlay();
        }
      } else if (availableTags.isEmpty) {
        resetSearch();
      }
    });
    ModelItem? existingItem = await ModelItem.get(widget.itemId);
    if (existingItem != null) {
      item = existingItem;
      itemTitleController.text = item.title;
      image = item.image;
      tags = await ModelItemTag.getTagsForItemId(widget.itemId);
      setState(() {});
    }
  }

  Future<void> _getPicture(ImageSource source) async {
    final pickedFile =
        await ImagePicker().pickImage(source: source);
    setState(() {
      processing = true;
    });
    if (pickedFile != null) {
      Uint8List bytes = await File(pickedFile.path).readAsBytes();
      image = await getResizedCroppedImage(bytes,512);
      itemChanged = true;
    }
    setState(() {
      processing = false;
    });
  }

  void updateAvailableTags(String query) async {
    if (query.isNotEmpty && query.length > 1) {
      availableTags = await ModelTag.search(query);
      if (availableTags.isNotEmpty) {
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

  void showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox =
        tagTextFieldKey.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    double overlayHeight = 100;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        height: overlayHeight,
        top: offset.dy - overlayHeight,
        width: size.width,
        child: Material(
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

  void resetSearch() {
    hideOverlay();
    itemTagController.clear();
    availableTags = [];
  }

  void hideOverlay() {
    entry?.remove();
    entry = null;
  }

  void addAvailableTag(ModelTag tag) {
    itemChanged = true;
    setState(() {
      checkAddTag(tag);
    });
  }

  void addNewTag() async {
    if (itemTagController.text.isEmpty) return;
    itemChanged = true;
    String tagTitle = itemTagController.text.trim();
    ModelTag tag = ModelTag(title: tagTitle);
    setState(() {
      checkAddTag(tag);
      resetSearch();
    });
  }

  void removeTag(ModelTag tag) async {
    if (item.id != null) {
      await ModelItemTag.removeForItemIdTagId(item.id!, tag.id!);
    }
    setState(() {
      tags.remove(tag);
    });
  }

  void checkAddTag(ModelTag newTag) {
    bool exist = false;
    for (ModelTag tag in tags) {
      if (tag.title == newTag.title) {
        exist = true;
        break;
      }
    }
    if (!exist) {
      tags.add(newTag);
    }
  }

  void saveItem() async {
    if (itemChanged) {
      String itemTitle = itemTitleController.text;
      if (itemTitle.isEmpty || image == null) {
        showAlertMessage(
            context, "Alert", "Please add image and some helpful text");
        return;
      } else {
        int? itemId = item.id;
        if (itemId == null) {
          // add new item
          itemId = await ModelItem(
                  profileId: profileId, title: itemTitle, image: image!)
              .insert();
        } else {
          // update item
          item.title = itemTitle;
          item.image = image!;
          int _ = await item.update();
        }
        for (ModelTag tag in tags) {
          int? tagId = tag.id;
          tagId ??= await tag.insert();
          tag.id = tagId;
          await ModelItemTag.checkAddItemTag(
            itemId,
            tagId,
          );
        }
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  void deleteItem() {
    item.delete();
    Navigator.of(context).pop();
  }

  Widget getBoxContent() {
    if (image != null) {
      return Image.memory(image!);
    } else if (processing) {
      return  const Card(child: Center(child: CircularProgressIndicator()));
    } else {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text("Tap to take a picutre with surroundings to locate it easily"),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getPicture(mobile ? ImageSource.camera : ImageSource.gallery);
    });
  }

  @override
  void dispose() {
    hideOverlay();
    itemTitleController.dispose();
    itemTagController.dispose();
    tagFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add/Edit Item"),
        actions: [
          if (widget.itemId > 0)
            IconButton(
                onPressed: deleteItem,
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ))
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
                      if (mobile) {
                        await _getPicture(ImageSource.camera);
                      } else {
                        await _getPicture(ImageSource.gallery);
                      }
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: SizedBox(
                        width: 150,
                        height: 150,
                        child: Center(child: getBoxContent()),
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
                          icon: const Icon(
                            Icons.publish,
                          ),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
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

  List<Widget> tagsView(List<ModelTag> tags) {
    return tags
        .map((e) => ListTile(
              title: Text(e.title),
              onTap: () {},
            ))
        .toList();
  }
}
