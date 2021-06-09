import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

class SearchBar extends StatefulWidget implements PreferredSizeWidget {
  final VoidCallback onCancelSearch;
  final Function(String) onSearchQueryChanged;
  final Function(String) onSearchSubmitted;
  final String? hintText;

  SearchBar({
    Key? key,
    required this.onCancelSearch,
    required this.onSearchQueryChanged,
    required this.onSearchSubmitted,
    this.hintText,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(56.0);

  @override
  _SearchBarState createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar>
    with SingleTickerProviderStateMixin {
  TextEditingController _searchFieldController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      child: Material(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black54),
                  onPressed: widget.onCancelSearch,
                ),
                Expanded(
                  child: TextField(
                    controller: _searchFieldController,
                    textAlignVertical: TextAlignVertical.center,
                    textInputAction: TextInputAction.search,
                    style: TextStyle(color: Colors.black54),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      prefixIcon: Icon(Icons.search, color: Colors.black54),
                      hintText: widget.hintText,
                      hintStyle: TextStyle(color: Colors.black54),
                    ),
                    onChanged: widget.onSearchQueryChanged,
                    onSubmitted: widget.onSearchSubmitted,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.clear, color: Colors.black54),
                  onPressed: _clearSearchQuery,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _clearSearchQuery() {
    _searchFieldController.clear();
    widget.onSearchQueryChanged('');
  }
}
