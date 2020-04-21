import 'package:demo_flutter/utils/ripple_painter.dart';
import 'package:flutter/material.dart';

class AnimatedAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(56.0);

  final AppBar primaryAppBar;
  final Widget secondaryContent;

  AnimatedAppBar({
    Key key,
    this.primaryAppBar,
    this.secondaryContent,
  }) : super(key: key);

  @override
  AnimatedAppBarState createState() => AnimatedAppBarState();
}

class AnimatedAppBarState extends State<AnimatedAppBar>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation _animation;

  double _rippleStartX, _rippleStartY;
  bool _secondaryContentVisible = false;

  @override
  initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.addStatusListener(_animationStatusListener);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        widget.primaryAppBar,
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => CustomPaint(
            painter: RipplePainter(
              containerHeight: widget.preferredSize.height,
              center: Offset(_rippleStartX ?? 0, _rippleStartY ?? 0),
              radius: _animation.value * screenWidth,
              context: context,
            ),
          ),
        ),
        _secondaryContentVisible ? widget.secondaryContent : Container(),
      ],
    );
  }

  void _animationStatusListener(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      setState(() => _secondaryContentVisible = true);
    }
  }

  void showSecondaryContent({Offset animationOrigin}) {
    setState(() {
      _rippleStartX = animationOrigin?.dx;
      _rippleStartY = animationOrigin?.dy;
    });

    _controller.forward();
  }

  void dismissSecondaryContent() {
    setState(() => _secondaryContentVisible = false);

    _controller.reverse();
  }
}
