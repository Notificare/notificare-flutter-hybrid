import 'package:demo_flutter/ui/widgets/search_bar.dart';
import 'package:demo_flutter/utils/ripple_painter.dart';
import 'package:flutter/material.dart';

class DefaultAppBar extends StatefulWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(56.0);

  final Widget title;
  final List<Widget> actions;
  final bool withSearch;
  final Function(String) onSearchQueryChanged;
  final Function(String) onSearchSubmitted;

  DefaultAppBar({
    this.title,
    this.actions,
    this.withSearch = false,
    this.onSearchQueryChanged,
    this.onSearchSubmitted,
  });

  @override
  _DefaultAppBarState createState() => _DefaultAppBarState();
}

class _DefaultAppBarState extends State<DefaultAppBar>
    with SingleTickerProviderStateMixin {
  double rippleStartX, rippleStartY;
  AnimationController _controller;
  Animation _animation;
  bool isInSearchMode = false;

  @override
  initState() {
    super.initState();

    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 200));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.addStatusListener(animationStatusListener);
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    final actions = List<Widget>();
    if (widget.actions != null) {
      actions.addAll(widget.actions);
    }

    if (widget.withSearch) {
      actions.add(GestureDetector(
        child: IconButton(
          icon: Icon(Icons.search, color: Colors.white),
          onPressed: null,
        ),
        onTapUp: onSearchTapUp,
      ));
    }

    return Stack(children: [
      AppBar(
        title: widget.title,
        actions: actions,
      ),
      AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => CustomPaint(
          painter: RipplePainter(
            containerHeight: widget.preferredSize.height,
            center: Offset(rippleStartX ?? 0, rippleStartY ?? 0),
            radius: _animation.value * screenWidth,
            context: context,
          ),
        ),
      ),
      isInSearchMode
          ? SearchBar(
              onCancelSearch: dismissSearch,
              onSearchQueryChanged: (query) {
                if (widget.onSearchQueryChanged != null) {
                  widget.onSearchQueryChanged(query);
                }
              },
              onSearchSubmitted: (query) {
                if (widget.onSearchSubmitted != null) {
                  widget.onSearchSubmitted(query);
                }

                dismissSearch();
              },
            )
          : Container()
    ]);
  }

  void animationStatusListener(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      setState(() {
        isInSearchMode = true;
      });
    }
  }

  void onSearchTapUp(TapUpDetails details) {
    setState(() {
      rippleStartX = details.globalPosition.dx;
      rippleStartY = details.globalPosition.dy;
    });

    _controller.forward();
  }

  void dismissSearch() {
    setState(() {
      isInSearchMode = false;
    });

    _controller.reverse();
  }
}
