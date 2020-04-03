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
      appBar: AppBar(
        title: Text('Onboarding'),
      ),
      body: PageView(
        controller: _pageController,
        children: _onboardingAssets.map((asset) {
          return Center(
            child: Text(asset.assetTitle),
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
}
