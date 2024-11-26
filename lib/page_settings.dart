
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'globals.dart';
import 'model_setting.dart';

class SettingsPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  const SettingsPage({
    super.key,
      required this.isDarkMode,
      required this.onThemeToggle,
    });

  @override
  SettingsPageState createState() => SettingsPageState();
}

class SettingsPageState extends State<SettingsPage> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          ListTile(
            title: const Text('Show all items'),
            trailing: Switch(
              value: ModelSetting.getForKey("show_all", false),
              onChanged: (bool value) {
                setState(() {
                  ModelSetting.update("show_all",value);
                });
              },
            ),
          ),
          const Divider(indent: 10.0,endIndent: 10.0,),
          ListTile(
            leading: const Icon(Icons.contrast),
            title: const Text("Theme"),
            onTap: widget.onThemeToggle,
            trailing: IconButton(
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  // Use both fade and rotation transitions
                  return FadeTransition(
                    opacity: animation,
                    child: RotationTransition(
                      turns: Tween<double>(begin: 0.75, end: 1.0).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Icon(
                  widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  key: ValueKey(widget.isDarkMode ? 'dark' : 'light'), // Unique key for AnimatedSwitcher
                  color: widget.isDarkMode ? Colors.orange : Colors.black,
                ),
              ),
              onPressed: () => widget.onThemeToggle(),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Rate App'),
            onTap: () => _redirectToFeedback(),
          ),
          ListTile(
            leading: const Icon(Icons.storage),
            title: const Text('Github Repo'),
            onTap: () => _redirectToGithub(),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () {_share();},
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final version = snapshot.data?.version ?? '';
                final buildNumber = snapshot.data?.buildNumber ?? '';
                return ListTile(
                  leading: const Icon(Icons.info),
                  title: Text('App Version: $version+$buildNumber'),
                  onTap: null,
                );
              } else {
                return const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('Loading...'),
                );
              }
            },
          ),
        ],
      )
    );
  }

  void _redirectToFeedback() {
    const url = 'https://play.google.com/store/apps/details?id=com.forget.it';
    // Use your package name
    openURL(url);
  }

  void _redirectToGithub() {
    const url = 'https://github.com/jeerovan/forgetit';
    // Use your package name
    openURL(url);
  }

  void _share() {
    const String appLink = 'https://play.google.com/store/apps/details?id=com.forget.it';
    Share.share("Add item location and forget it: $appLink");
  }
}