import 'package:demo_flutter/theme/notificare_colors.dart';
import 'package:flutter/material.dart';
import 'package:notificare_push_lib/notificare_models.dart';
import 'package:notificare_push_lib/notificare_push_lib.dart';

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
      body: PageView(
        controller: _pageController,
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
                        style: TextStyle(
                          color: NotificareColors.gray,
                          fontSize: 20,
                          fontFamily: 'Lato',
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
                        child: Text(
                          asset.assetButton.label.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Lato',
                          ),
                        ),
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

  _onButtonPressed(NotificareAsset asset) {}
}
