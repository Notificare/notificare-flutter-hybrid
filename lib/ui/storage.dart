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
            children:
                _assets.map<Widget>((asset) => _buildAssetItem(asset)).toList(),
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

  Widget _buildAssetItem(NotificareAsset asset) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Container(
              child: _buildAssetImage(asset),
            ),
          ),
          Padding(padding: EdgeInsets.only(top: 8)),
          Center(
            child: Text(
              asset.assetTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.body1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetImage(NotificareAsset asset) {
    final contentType = asset.assetMetaData?.contentType;
    var imageWidget;

    switch (contentType) {
      case 'image/jpeg':
      case 'image/gif':
      case 'image/png':
        imageWidget = Image.network(asset.assetUrl);
        break;
      case 'video/mp4':
        imageWidget = Image.asset('assets/images/asset_video.png');
        break;
      case 'application/pdf':
        imageWidget = Image.asset('assets/images/asset_pdf.png');
        break;
      case 'application/json':
        imageWidget = Image.asset('assets/images/asset_json.png');
        break;
      case 'text/javascript':
        imageWidget = Image.asset('assets/images/asset_js.png');
        break;
      case 'text/css':
        imageWidget = Image.asset('assets/images/asset_css.png');
        break;
      case 'text/html':
        imageWidget = Image.asset('assets/images/asset_html.png');
        break;
      case 'audio/mp3':
        imageWidget = Image.asset('assets/images/asset_sound.png');
        break;
      default:
        imageWidget = Image.asset('assets/images/asset_text.png');
    }

    return imageWidget;
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
