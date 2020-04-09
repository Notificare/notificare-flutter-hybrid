import 'package:demo_flutter/ui/widgets/default_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

class Storage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StorageState();
}

class _StorageState extends State<Storage> {
  final _notificare = NotificarePushLib();
  bool _isInitialRender = true;
  bool _isLoading = false;
  final _assets = List<NotificareAsset>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DefaultAppBar(
        title: Text('Storage'),
        withSearch: true,
        onSearchQueryChanged: (query) => setState(() {
          _isInitialRender = true;
          _assets.clear();
        }),
        onSearchSubmitted: (query) => _fetchAssets(query),
      ),
      body: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          GridView.count(
            crossAxisCount: 2,
            children: _assets.map<Widget>((asset) {
              return Image.asset('assets/images/no_attachment.png');
            }).toList(),
          ),
          Visibility(
            visible: !_isLoading && _assets.isEmpty,
            child: Container(
              padding: EdgeInsets.all(16),
              child: Text(
                _isInitialRender
                    ? 'Use the search option above to search for asset groups created in the dashboard.'
                    : 'No asset group found',
                style: Theme.of(context).textTheme.body1,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Visibility(
            visible: _isLoading,
            child: CircularProgressIndicator(),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchAssets(String group) async {
    setState(() {
      _isInitialRender = false;
      _isLoading = true;
      _assets.clear();
    });

    try {
      final result = await _notificare.fetchAssets(group);

      setState(() {
        _isLoading = false;
        _assets.addAll(result);
      });
    } catch (err) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class AssetsSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () => query = '',
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    print('Build results: $query');
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    print('Build suggestions: $query');
    return Container();
  }
}
