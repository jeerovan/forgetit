import 'package:flutter/material.dart';
import 'package:forgetit/add_edit_item.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_profile.dart';
import 'package:forgetit/model_setting.dart';
import 'package:forgetit/page_profile.dart';

import 'globals.dart';
import 'page_db.dart';

bool debug = true;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int profileId = ModelSetting.getForKey("profile", 1);

  final TextEditingController searchController = TextEditingController();

  ModelItem lastAdded = ModelItem.init();
  List<ModelItem> items = [];
  ModelProfile profile = ModelProfile.init();

  void init() {
    loadProfile(profileId);
  }
  
  void loadProfile(int selectedProfileId) async {
    profileId = selectedProfileId;
    await ModelSetting.update("profile", selectedProfileId);
    ModelProfile? existingProfile = await ModelProfile.get(selectedProfileId);
    if (existingProfile != null){
      profile = existingProfile;
    }
    ModelItem? item = await ModelItem.getLastAdded(profileId);
    if (item != null) {
      lastAdded = item;
    } else {
      lastAdded = ModelItem.init();
    }
    setState(() {
    });
  }

  void addEditItem(int itemId) {
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => AddEditItem(itemId: itemId),
        )).then((_) => init() // refresh recently added entries
        );
  }

  void resetSearch() {
    items = [];
    searchController.clear();
    setState(() {});
  }

  void searchItems(String query) async {
    if (query.length > 1) {
      items = await ModelItem.getForTag(query, profileId);
    } else {
      items = [];
    }
  }

  void selectProfile(){
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ProfilePage(
        onSelect : (id) {
          loadProfile(id);
        }
      )
    ));
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forget It"),
        actions: [
          if (debug)
            IconButton(
                icon: const Icon(Icons.reorder),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DatabasePage(),
                  ));
                })
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: itemsView(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: <Widget>[
                IconButton(
                  icon: ClipOval(
                    child: Image.memory(
                      profile.id != null && profile.image.isNotEmpty ? profile.image : getBlankImage(512),
                      width: 45,
                      height: 45,
                      fit: BoxFit.cover,
                    ),
                  ),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    selectProfile();
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: TextField(
                      controller: searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search by a tag',
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                ),
                                onPressed: () => resetSearch(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(16.0),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchItems(value);
                        });
                      },
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    addEditItem(0);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget itemsView() {
    if (items.isEmpty) {
      if (lastAdded.id == null) {
        return  Text("Add Items",style: Theme.of(context).textTheme.titleMedium,);
      } else {
        return Column(
          children: [
            Center(
              child: Text(
                "Last Added",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            GestureDetector(
              onTap: () => addEditItem(lastAdded.id!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: SizedBox(
                  width: 200,
                  height: 200,
                  child: lastAdded.image.isEmpty
                      ? const Text("Image not available")
                      : Image.memory(lastAdded.image,fit: BoxFit.cover,),
                ),
              ),
            ),
          ],
        );
      }
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Wrap(
            spacing: 10.0,
            runSpacing: 15.0,
            children: items.map((item) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: SizedBox(
                  width: 150,
                  height: 150,
                  child: Image.memory(item.image),
                ),
              );
            }).toList(),
          ),
        ),
      );
    }
  }
}
