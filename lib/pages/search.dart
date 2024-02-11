import 'package:flutter/material.dart';

import '../models/point_data.dart';

class Search extends StatelessWidget {
  Search(
      {Key? key,
      required this.map,
      required this.data,
      required this.onSelect,
      required this.mapContext,
      required this.zoomTo})
      : super(key: key);
  final Widget map;
  final List<PointData> data;
  final Function(
          BuildContext, String, String, String, double, double, String, String)
      onSelect;
  final BuildContext mapContext;
  final Function(double, double) zoomTo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: map,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerTop,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(top: 30.0),
        child: ElevatedButton(
          onPressed: () {
            showSearch(
              context: context,
              delegate: CustomSearchDelegate(
                  data: data,
                  onSelect: onSelect,
                  mapContext: mapContext,
                  zoomTo: zoomTo),
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
  CustomSearchDelegate(
      {required this.data,
      required this.onSelect,
      required this.mapContext,
      required this.zoomTo});
  final List<PointData> data;
  final BuildContext mapContext;
  final Function(
          BuildContext, String, String, String, double, double, String, String)
      onSelect;
  final Function(double, double) zoomTo;

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
    List<Map<String, dynamic>> suggestionList = [];

    if (query.isEmpty) {
      suggestionList = data
          .map((marker) => {
                'title': marker.title,
                'description': marker.description,
                'latitude': marker.latitude,
                'longitude': marker.longitude,
                'creator': marker.creator,
                'eventType': marker.eventType,
                'time': marker.formattedDate
              })
          .toList();
    } else {
      suggestionList = data
          .where((marker) =>
              marker.description.toLowerCase().contains(query.toLowerCase()) ||
              marker.title.toLowerCase().contains(query.toLowerCase()))
          .map((marker) => {
                'title': marker.title,
                'description': marker.description,
                'latitude': marker.latitude,
                'longitude': marker.longitude,
                'creator': marker.creator,
                'eventType': marker.eventType,
                'time': marker.formattedDate
              })
          .toList();
    }

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (listContext, index) {
        return ListTile(
            title: Text(suggestionList[index]['title'] ?? ''),
            onTap: () {
              var selected = suggestionList[index];
              Navigator.pop(listContext);
              zoomTo(selected['latitude'] as double,
                  selected['longitude'] as double);
              onSelect(
                  mapContext,
                  selected['title'],
                  selected['creator'],
                  selected['description'],
                  selected['latitude'] as double,
                  selected['longitude'] as double,
                  selected['eventType'],
                  selected['time']);
            });
      },
    );
  }
}
