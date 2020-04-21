import 'package:demo_flutter/ui/widgets/animated_app_bar.dart';
import 'package:demo_flutter/ui/widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:url_launcher/url_launcher.dart';

class Storage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _StorageState();
}

class _StorageState extends State<Storage> {
  final _notificare = NotificarePushLib();
  final _assets = List<NotificareAsset>();
  final _appBarKey = GlobalKey<AnimatedAppBarState>();

  bool _isInitialRender = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AnimatedAppBar(
        key: _appBarKey,
        primaryAppBar: AppBar(
          title: Text('Storage'),
          actions: <Widget>[
            GestureDetector(
              child: IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: null,
              ),
              onTapUp: (tapDetails) {
                _appBarKey.currentState?.showSecondaryContent(
                  animationOrigin: tapDetails.globalPosition,
                );
              },
            )
          ],
        ),
        secondaryContent: SearchBar(
          onCancelSearch: () {
            _appBarKey.currentState?.dismissSecondaryContent();
          },
          onSearchQueryChanged: (query) {
            setState(() {
              _isInitialRender = true;
              _assets.clear();
            });
          },
          onSearchSubmitted: (query) {
            _fetchAssets(query);
            _appBarKey.currentState?.dismissSecondaryContent();
          },
        ),
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
                style: Theme.of(context).textTheme.caption,
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
    return InkWell(
      onTap: () => _showAsset(asset),
      child: Container(
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

  Future<void> _showAsset(NotificareAsset asset) async {
    final contentType = asset.assetMetaData?.contentType;
    switch (contentType) {
      case 'image/jpeg':
      case 'image/gif':
      case 'image/png':
      case 'video/mp4':
      case 'application/pdf':
      case 'text/html':
      case 'audio/mp3':
        if (asset.assetUrl != null) {
          if (await canLaunch(asset.assetUrl)) {
            launch(asset.assetUrl);
          }
        }
        break;
    }
  }
}
