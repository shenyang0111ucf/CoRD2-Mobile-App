import 'package:cord2_mobile_app/pages/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cord2_mobile_app/pages/sign_on.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
            top: 50.0,
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
      )
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



