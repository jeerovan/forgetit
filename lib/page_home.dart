import 'package:flutter/material.dart';
import 'package:forgetit/add_edit_item.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_profile.dart';
import 'package:forgetit/model_setting.dart';
import 'package:forgetit/page_profile.dart';

import 'globals.dart';
import 'page_db.dart';
import 'page_settings.dart';

bool debug = false;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int profileId = ModelSetting.getForKey("profile", 1);

  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

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
    items = await getItems();
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

  void resetSearch() async {
    items = await getItems();
    searchController.clear();
    setState(() {});
  }

  Future<List<ModelItem>> getItems() async {
    if (ModelSetting.getForKey("show_all", false)){
      return await ModelItem.getAll(profileId);
    } else {
      return [];
    }
  }

  void searchItems(String query) async {
    if (query.length > 1) {
      items = await ModelItem.getForTag(query, profileId);
    } else {
      items = await getItems();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(searchFocusNode);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forget It"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () {
              Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                )).then((_) => init() // refresh recently added entries
                );
          }) ,
          if (debug)
            IconButton(
                icon: const Icon(Icons.reorder),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DatabasePage(),
                  ));
                }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: pageView(),
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
                      focusNode: searchFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Search with a tag',
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
                          searchItems(value.trim());
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

  Widget pageView() {
    bool showAll = ModelSetting.getForKey("show_all", false);
    if (searchController.text.isEmpty){
      if (lastAdded.id == null) {
        return  Center(child: Text("Tap on + to add items",style: Theme.of(context).textTheme.titleMedium,));
      } else if (items.length == 1){
        return singleItemView();
      } else if(showAll) {
        return itemsView();
      } else {
        return singleItemView();
      }
    } else if (items.isEmpty) {
      return  Center(child: Text("No items found",style: Theme.of(context).textTheme.titleMedium,));
    } else {
      return itemsView();
    }
  }

  Widget singleItemView(){
    return SingleChildScrollView(
      child: Column(
        children: [
          Center(
            child: Text(
              "Last Added",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(height: 8,),
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
          const SizedBox(height: 16,),
          ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: const SizedBox(
                width: 200,
                height: 200,
                child: Center(child: Text("Tap on image above to edit it or + below to add items")),
              ),
            ),
        ],
      ),
    );
  }

  Widget itemsView() {
    return SingleChildScrollView(
      child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 10.0,
            runSpacing: 15.0,
            children: items.map((item) {
              return GestureDetector(
                onTap: () => addEditItem(item.id!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: Image.memory(item.image),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
    );
  }
}
