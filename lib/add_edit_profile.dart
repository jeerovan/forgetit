import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:forgetit/model_profile.dart';
import 'package:image_picker/image_picker.dart';

import 'globals.dart';

class AddEditProfile extends StatefulWidget {
  final int profileId;
  final Function() onUpdate;
  const AddEditProfile({super.key,required this.profileId,required this.onUpdate});

  @override
  AddEditProfileState createState() => AddEditProfileState();
}

class AddEditProfileState extends State<AddEditProfile> {
  final TextEditingController profileController = TextEditingController();

  ModelProfile profile = ModelProfile.init();

  bool processing = false;
  bool itemChanged = false;

  void init() async {
    ModelProfile? existingProfile = await ModelProfile.get(widget.profileId);
    if (existingProfile != null){
      setState(() {
        profile = existingProfile;
        profileController.text = profile.title;
      });
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
      profile.image = await compute(getResizedCroppedImage, bytes);
      itemChanged = true;
    }
    setState(() {
      processing = false;
    });
  }

  void saveProfile() async {
    if (itemChanged){
      if (profile.id == null){
        await profile.insert();
      } else {
        await profile.update();
      }
      widget.onUpdate();
    }
    if(mounted)Navigator.of(context).pop();
  }

  Widget getBoxContent() {
    if (processing) {
      return  const Card(child: Center(child: CircularProgressIndicator()));
    } else if (profile.image.isNotEmpty) {
      return Image.memory(profile.image);
    } else {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child:
                Text("Tap to set profile image"),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Profile",style: Theme.of(context).textTheme.labelLarge),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    await _getPicture(ImageSource.gallery);
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
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: profileController,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Profile Title', // Placeholder
                    ),
                    onChanged: (value) {
                      profile.title = value.trim();
                      itemChanged = true;
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              color: Theme.of(context).colorScheme.primary,
              icon: const Icon(Icons.check),
              onPressed: () {
                saveProfile();
              },
            ),
          ),
        ],
      ),
    );
  }
}