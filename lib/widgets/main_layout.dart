import 'package:flutter/material.dart';

class MainLayout extends StatelessWidget {
  final Widget body;
  final String title;

  const MainLayout({super.key, required this.body, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add menu
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'NDLS Gallery',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Photos'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Photos screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_album),
              title: const Text('Albums'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Albums screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Favorites'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Favorites screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('Trash'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to Trash screen
              },
            ),
          ],
        ),
      ),
      body: body,
    );
  }
}
