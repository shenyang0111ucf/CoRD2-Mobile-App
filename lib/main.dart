import 'package:cord2_mobile_app/pages/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SignOnPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String currentPage = "Map"; // Track the current page
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Your content goes here
          _getPageContent(
              currentPage), // Show content based on the current page
          // Circular menu button
          Positioned(
            top: 30.0,
            left: 10.0,
            child: InkWell(
              onTap: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue,
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'CoRD2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            _buildDrawerItem("Map"),
            _buildDrawerItem("Report"),
            _buildDrawerItem("Chat"),
            _buildDrawerItem("Profile"),
            const Divider(),
            ListTile(
              title: const Text('Log Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                    context, MaterialPageRoute(builder: (context) => SignOnPage()), (Route route) => false);
              },
            ),
          ],
        ),
    return MaterialApp(
      title: 'CoRD2 Mobile Application',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff5F79BA)),
        useMaterial3: true,
      ),
      home: const SignOnPage(),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Overlay Example'),
      ),
      body: Center(
        child: Text('Your main content goes here'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: ElevatedButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(),
            );
          },
          style: ElevatedButton.styleFrom(
            primary: Theme.of(context).primaryColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search...',
                style: TextStyle(color: Colors.white),
              ),
              SizedBox(width: 50.0),
              Icon(Icons.search, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDrawerItem(String pageName) {
    return ListTile(
      title: Text(pageName),
      onTap: () {
        // Add navigation to the selected page
        Navigator.pop(_scaffoldKey.currentContext!); // Close the drawer
        _navigateToPage(pageName);
      },
    );
  }

  Widget _getPageContent(String pageName) {
    // Return the respective page content based on the selected page
    switch (pageName) {
      case "Map":
        return Center(child: DisplayMap());
      case "Report":
        return Center(child: Text('Report Content'));
      case "Chat":
        return Center(child: Text('Chat Content'));
      case "Profile":
        return Center(child: Text('Profile Content'));
      default:
        return Container(); // Default empty container
    }
  }

  void _navigateToPage(String pageName) {
    // Navigate to the selected page
    setState(() {
      currentPage = pageName;
    });
  }
}

class CustomSearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, "");
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('events').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return CircularProgressIndicator();
        }

        final List<Map<String, dynamic>> suggestionList = query.isEmpty
            ? (snapshot.data as QuerySnapshot)
                .docs
                .where((doc) => doc['active'] == true)
                .map((doc) => {
                      'title': doc['title'] as String,
                      'description': doc['description'] as String,
                    })
                .toList()
            : (snapshot.data as QuerySnapshot)
                .docs
                .where((doc) => doc['active'] == true)
                .map((doc) => {
                      'title': doc['title'] as String,
                      'description': doc['description'] as String,
                    })
                .where((element) =>
                    element['title'] != null &&
                    element['title']!
                        .toLowerCase()
                        .contains(query.toLowerCase()))
                .toList();

        return ListView.builder(
          itemCount: suggestionList.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(suggestionList[index]['title'] ?? ''),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReportPage(
                      description: suggestionList[index]['description'] ?? '',
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class ReportPage extends StatelessWidget {
  final String description;

  ReportPage({required this.description});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Report Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(description),
      ),
    );
  }
}
