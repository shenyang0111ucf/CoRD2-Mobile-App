import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final Function(BuildContext, PointData) onSelect;
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
        padding: const EdgeInsets.only(top: 10.0),
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
            backgroundColor: const Color(0xff242C73),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Search...',
                style: GoogleFonts.jost(
                    textStyle: TextStyle(
                        color: Colors.white, height: 1.0, fontSize: 18)),
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
  final Function(BuildContext, PointData) onSelect;
  final Function(double, double) zoomTo;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
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
    List<PointData> suggestionList = [];
    if (query.isEmpty) {
      suggestionList = data;
    } else {
      suggestionList = data
          .where((marker) =>
              marker.description.toLowerCase().contains(query.toLowerCase()) ||
              marker.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (listContext, index) {
        return ListTile(
            title: Text(suggestionList[index].title ?? ''),
            onTap: () {
              var selected = suggestionList[index];
              Navigator.pop(listContext);
              zoomTo(selected.latitude, selected.longitude);
              onSelect(mapContext, selected);
            });
      },
    );
  }
}
