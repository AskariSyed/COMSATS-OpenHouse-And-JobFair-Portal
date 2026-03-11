import 'package:flutter/material.dart';

class AppPageReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double beginOffsetY;
  final Curve curve;

  const AppPageReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 420),
    this.beginOffsetY = 20,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<AppPageReveal> createState() => _AppPageRevealState();
}

class _AppPageRevealState extends State<AppPageReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: widget.curve);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final offsetY = (1 - _animation.value) * widget.beginOffsetY;

        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(offset: Offset(0, offsetY), child: child),
        );
      },
    );
  }
}

class AppStaggeredReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final int maxDelaySteps;
  final Duration stepDelay;
  final Duration duration;
  final double beginOffsetY;

  const AppStaggeredReveal({
    super.key,
    required this.child,
    required this.index,
    this.maxDelaySteps = 6,
    this.stepDelay = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 380),
    this.beginOffsetY = 16,
  });

  @override
  State<AppStaggeredReveal> createState() => _AppStaggeredRevealState();
}

class _AppStaggeredRevealState extends State<AppStaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    final delaySteps = widget.index > widget.maxDelaySteps
        ? widget.maxDelaySteps
        : widget.index;
    await Future<void>.delayed(widget.stepDelay * delaySteps);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        final offsetY = (1 - _animation.value) * widget.beginOffsetY;

        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(offset: Offset(0, offsetY), child: child),
        );
      },
    );
  }
}

// 🔹 NEW: Animation for expanding cards with content fade-in
class AppExpandableAnimation extends StatelessWidget {
  final Widget child;
  final bool isExpanded;
  final Duration duration;
  final double beginOpacity;

  const AppExpandableAnimation({
    super.key,
    required this.child,
    required this.isExpanded,
    this.duration = const Duration(milliseconds: 600),
    this.beginOpacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isExpanded ? 1.0 : beginOpacity,
      duration: duration,
      child: AnimatedSize(
        duration: duration,
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: isExpanded ? child : const SizedBox.shrink(),
      ),
    );
  }
}

// 🔹 NEW: Fade-in animation for loading content (charts, graphs)
class AppLoadingFadeIn extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AppLoadingFadeIn({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  State<AppLoadingFadeIn> createState() => _AppLoadingFadeInState();
}

class _AppLoadingFadeInState extends State<AppLoadingFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future<void>.delayed(widget.delay);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation, child: widget.child);
  }
}

// 🔹 NEW: Bar chart animation from bottom-to-up
class AppBarChartReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AppBarChartReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1200),
    this.delay = const Duration(milliseconds: 200),
  });

  @override
  State<AppBarChartReveal> createState() => _AppBarChartRevealState();
}

class _AppBarChartRevealState extends State<AppBarChartReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future<void>.delayed(widget.delay);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Transform.translate(
            offset: Offset(0, (1 - _animation.value) * 30),
            child: child,
          ),
        );
      },
    );
  }
}

// 🔹 NEW: Pie chart circular rotation animation
class AppPieChartReveal extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const AppPieChartReveal({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.delay = const Duration(milliseconds: 300),
  });

  @override
  State<AppPieChartReveal> createState() => _AppPieChartRevealState();
}

class _AppPieChartRevealState extends State<AppPieChartReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _rotationAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _startAnimation();
  }

  Future<void> _startAnimation() async {
    await Future<void>.delayed(widget.delay);
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value * 6.28, // 360 degrees in radians
            child: child,
          ),
        );
      },
    );
  }
}
