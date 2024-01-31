import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'map.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(
        child: DisplayMap(),
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
          child: const Row(
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
              onTap: () {}
                );
              },
            );
          },
        );
      },
    );
  }
}
