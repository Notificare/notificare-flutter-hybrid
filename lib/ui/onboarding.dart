import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:demo_flutter/utils/globals.dart';
import 'package:demo_flutter/utils/storage_manager.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';
import 'package:permission_handler/permission_handler.dart';

class Onboarding extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  final _notificare = NotificarePushLib();
  PageController _pageController;
  final _onboardingAssets = List<NotificareAsset>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _fetchOnboarding();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.black,
        ),
      ),
      body: WillPopScope(
        onWillPop: _onWillPop,
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: _onboardingAssets.map((asset) {
            return Stack(
              alignment: AlignmentDirectional.topCenter,
              fit: StackFit.expand,
              children: <Widget>[
                Image.network(asset.assetUrl,
                    alignment: AlignmentDirectional.topCenter),
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Expanded(child: Container()),
                      Container(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Text(
                          asset.assetTitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.title.copyWith(
                            color: NotificareColors.gray,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(minWidth: double.infinity),
                        child: RaisedButton(
                          color: NotificareColors.outerSpace,
                          textColor: Colors.white,
                          padding: EdgeInsets.all(15),
                          child: Text(asset.assetButton.label.toUpperCase()),
                          onPressed: () => _onButtonPressed(asset),
                        ),
                      )
                    ],
                  ),
                )
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  _fetchOnboarding() async {
    try {
      final assets = await _notificare.fetchAssets("ONBOARDING");
      setState(() {
        _onboardingAssets.clear();
        _onboardingAssets.addAll(assets);
      });
    } catch (err) {
      debugPrint('Failed to load the onboarding assets: $err');
    }
  }

  _onButtonPressed(NotificareAsset asset) {
    switch (asset.assetButton.action) {
      case 'goToLocationServices':
        _notificare.registerForNotifications();
        break;
      case 'goToApp':
        _startLocationUpdates();
        return;
    }

    _pageController.nextPage(
      duration: kViewPagerAnimationDuration,
      curve: kViewPagerAnimationCurve,
    );
  }

  Future<bool> _onWillPop() {
    if (_pageController.page.round() == _pageController.initialPage)
      return Future.value(true);
    else {
      _pageController.previousPage(
        duration: kViewPagerAnimationDuration,
        curve: kViewPagerAnimationCurve,
      );

      return Future.value(false);
    }
  }

  _startLocationUpdates() async {
    try {
      final permission = await Permission.location.request();

      if (permission == PermissionStatus.granted) {
        _notificare.startLocationUpdates();
        _notificare.enableBeacons();

        // Do not show the on-boarding again, we're done.
        await StorageManager.setOnboardingStatus(true);

        // Now yes, let's move into the home page.
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (err) {
      debugPrint('Failed to get the location permission: $err');
    }
  }
}
