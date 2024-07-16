import 'package:flutter/material.dart';
import 'package:forgetit/globals.dart';

import 'model_profile.dart';

class ProfilePage extends StatefulWidget {
  final Function(int) onSelect;
  const ProfilePage({super.key,required this.onSelect});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  List<ModelProfile> profiles = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profiles"),
      ),
      body: FutureBuilder(
        future: ModelProfile.all(), 
        builder: (context,snapshot){
          if (snapshot.connectionState == ConnectionState.done) {
            List<ModelProfile> profiles = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text("Tap to select Or long press to edit",
                      style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 16,),
                    Center(
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 16.0,
                        children: profiles.map((profile) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              GestureDetector(
                                onTap: () {
                                    widget.onSelect(profile.id!);
                                    Navigator.of(context).pop();
                                  },
                                  onLongPress: () {
                                  },
                                child: ClipOval(
                                  child: Image.memory(
                                    profile.image.isEmpty ? getBlankImage(512) : profile.image,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Text(profile.title),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16,),
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle button press
                          },
                          style: ElevatedButton.styleFrom(
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(20),
                          ),
                          child: const Icon(Icons.add, size: 40),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else {
            return const Scaffold();
          }
        }
      )
    );
  }
}
