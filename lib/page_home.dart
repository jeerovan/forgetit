
import 'package:flutter/material.dart';
import 'package:forgetit/add_edit_item.dart';
import 'package:forgetit/globals.dart';
import 'package:forgetit/model_item.dart';
import 'package:forgetit/model_setting.dart';

import 'page_db.dart';

bool debug = false;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  ModelItem lastAdded = ModelItem.init();
  List<ModelItem> items = [];
  
  void loadLastAddedItem() async {
    ModelItem? item = await ModelItem.getLastAdded();
    if(item != null){
      setState(() {
        lastAdded = item;
      });
    }
  }
  void addEditItem(int itemId){
    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (context) => AddEditItem(itemId: itemId),
      )).then((_) => loadLastAddedItem() // refresh recently added entries
      );
  }
  void resetSearch(){
    items = [];
    searchController.clear();
    setState(() {
    });
  }
  void searchItems(String query) async {
    if (query.length > 1){
      int profileId = ModelSetting.getForKey("profile", 1);
      items = await ModelItem.getForTag(query, profileId);
    } else {
      items = [];
    }
  }
  @override
  void initState() {
    super.initState();
    loadLastAddedItem();
  }
  @override
  void dispose(){
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forget It"),
        actions: [
          if(debug)IconButton(
            icon: const Icon(Icons.reorder), 
            onPressed: () {
              Navigator.of(context)
                .push(MaterialPageRoute(
                  builder: (context) => const DatabasePage(),
                ));
          })
        ],
      ),
      body: itemsView(),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.face),
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {
                Navigator.of(context)
                  .push(MaterialPageRoute(
                    builder: (context) => const BlankPage(),
                  ));
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
                          icon: const Icon(Icons.clear,),
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
    );
  }
  Widget itemsView() {
    if (items.isEmpty){
      if (lastAdded.id == null){
        return const Center(child: Text("Add Items"));
      } else {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                "Last Added",
                style: Theme.of(context).textTheme.titleMedium,),
            ),
            GestureDetector(
              onTap: () => addEditItem(lastAdded.id!),
              child: SizedBox(
                width: 200,
                height: 200,
                child: Card(
                  child: Center(
                    child: lastAdded.image.isEmpty ? 
                      const Text("Image not available")
                      :Image.memory(lastAdded.image)
                  ),
                ),
              ),
            ),
          ],
        );
      }
    } else {
      return SingleChildScrollView(
        child: Center(
          child: Wrap(
            spacing: 10.0,
            runSpacing: 10,
            children: items.map((item) {
              return SizedBox(
                    width: 150,
                    height: 150,
                    child: Card(
                      child: Center(
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
}