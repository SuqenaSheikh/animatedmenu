// - CustomPainter creates a morphing side panel with cubic curves
// - Drag from left edge to reveal; controller animates open/close
// - Main content scales slightly for depth; scrim fades in
// - Menu items slide+fade with a simple stagger

import 'dart:math' as math;
import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';

class LiquidSideMenuController extends InheritedWidget {
  const LiquidSideMenuController({
    super.key,
    required this.state,
    required super.child,
  });

  final _LiquidSideMenuScaffoldState state;

  static _LiquidSideMenuScaffoldState of(BuildContext context) {
    final widget = context
        .dependOnInheritedWidgetOfExactType<LiquidSideMenuController>();
    assert(widget != null, 'LiquidSideMenuController not found in context');
    return widget!.state;
  }

  @override
  bool updateShouldNotify(covariant LiquidSideMenuController oldWidget) {
    return oldWidget.state != state;
  }

  // Convenience methods
  bool get isOpen => state.isOpen;

  void open() => state.open();

  void close() => state.close();

  void toggle() => state.toggle();
}

// Public Scaffold to wrap your page
class LiquidSideMenuScaffold extends StatefulWidget {
  const LiquidSideMenuScaffold({
    super.key,
    required this.child,
    required this.menuItems,
    required this.menuHeader,
    this.onSelect,
    this.maxMenuWidth = 300,
    this.curveDepth = 42,
    this.revealStyle = LiquidRevealStyle.bubble, // default to bubble like video
  });

  final Widget child;
  final List<Widget> menuItems;
  final Widget menuHeader;
  final void Function(int index)? onSelect;

  // Max panel width and curve bulge depth (panel mode)
  final double maxMenuWidth;
  final double curveDepth;

  // Bubble vs panel reveal
  final LiquidRevealStyle revealStyle;

  @override
  State<LiquidSideMenuScaffold> createState() => _LiquidSideMenuScaffoldState();
}

enum LiquidRevealStyle { panel, bubble }

class _LiquidSideMenuScaffoldState extends State<LiquidSideMenuScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Drag tracking
  double _dragX = 0;
  double _dragY = 0;
  bool _dragging = false;

  // Expose status
  bool get isOpen => _controller.value > 0.95;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      value: 0,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void open() => _controller.animateTo(
    1,
    curve: Curves.easeOutCubic,
    duration: const Duration(milliseconds: 900),
  );

  void close() => _controller.animateTo(
    0,
    curve: Curves.easeInCubic,
    duration: const Duration(milliseconds: 900),
  );

  void toggle() => isOpen ? close() : open();

  void _onDragStart(DragStartDetails d) {
    _dragging = true;
    _dragY = d.localPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragX = (_dragX + d.delta.dx).clamp(0, widget.maxMenuWidth + 120);
    _dragY = d.localPosition.dy;

    // Map drag to controller value
    final t = (_dragX / widget.maxMenuWidth).clamp(0.0, 1.0);
    _controller.value = t;
    setState(() {});
  }

  void _onDragEnd(DragEndDetails d) {
    _dragging = false;

    // Velocity/threshold settle
    final v = d.velocity.pixelsPerSecond.dx;
    final openThreshold = 0.42;
    if (v > 600 || _controller.value > openThreshold) {
      open();
    } else {
      close();
    }

    // Reset dragX softly (visual curve uses value + drag extras)
    _dragX = 0;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isBubble = widget.revealStyle == LiquidRevealStyle.bubble;

    return LiquidSideMenuController(
      state: this,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;

          // Main content transform
          final contentScale = lerpDouble(1.0, isBubble ? 0.94 : 0.94, t)!;
          final contentTranslate = isBubble
              ? 0.0
              : lerpDouble(0, widget.maxMenuWidth * 0.28, t)!;
          final contentRadius = lerpDouble(0, isBubble ? 18 : 24, t)!;

          return Stack(
            children: [
              // Background liquid
              Positioned.fill(
                child: CustomPaint(
                  painter: isBubble
                      ? _BubbleRevealPainter(t: t, color: cs.primary)
                      : _LiquidMenuPainter(
                          t: t,
                          dragX: _dragX,
                          dragY: _dragY,
                          dragging: _dragging,
                          maxWidth: widget.maxMenuWidth,
                          curveDepth: widget.curveDepth,
                          color: cs.primary,
                        ),
                ),
              ),

              // Menu content
              if (isBubble)
                // Full-screen overlay menu in bubble mode
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: t < 0.3,
                    child: Opacity(
                      opacity: Curves.easeOut.transform(
                        ((t - 0.35) / 0.65).clamp(0.0, 1.0),
                      ),
                      child: SafeArea(
                        child: _FullScreenMenuContent(
                          header: widget.menuHeader,
                          items: widget.menuItems,
                          onSelect: widget.onSelect,
                          progress: t,
                        ),
                      ),
                    ),
                  ),
                )
              else
                // Side panel menu in panel mode
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: lerpDouble(0, widget.maxMenuWidth, t),
                  child: IgnorePointer(
                    ignoring: t < 0.05,
                    child: Opacity(
                      opacity: Curves.easeOut.transform(t),
                      child: SafeArea(
                        child: _MenuContent(
                          header: widget.menuHeader,
                          items: widget.menuItems,
                          onSelect: widget.onSelect,
                          progress: t,
                        ),
                      ),
                    ),
                  ),
                ),

              // Scrim overlay (tap anywhere to close)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: t <= 0.001,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: close,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      color: Colors.black.withOpacity(0.28 * t),
                    ),
                  ),
                ),
              ),

              // Main content (scaled/rounded)
              // Main content (scaled/hidden when menu opens)
              Positioned.fill(
                child: AnimatedOpacity(
                  opacity: 1.0 - t, // fade out main content as menu opens
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: t > 0.1, // disable touches when menu is open
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: t),
                      duration: const Duration(milliseconds: 120),
                      builder: (context, _, child) {
                        return Transform.translate(
                          offset: Offset(contentTranslate, 0),
                          child: Transform.scale(
                            scale: contentScale,
                            alignment: isBubble
                                ? Alignment.center
                                : Alignment.centerRight,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                contentRadius,
                              ),
                              child: child,
                            ),
                          ),
                        );
                      },
                      child: isBubble
                          ? Semantics(
                              label: 'Main content',
                              container: true,
                              child: widget.child,
                            )
                          : _EdgeDragRegion(
                              isOpen: isOpen,
                              onDragStart: _onDragStart,
                              onDragUpdate: _onDragUpdate,
                              onDragEnd: _onDragEnd,
                              child: Semantics(
                                label: 'Main content',
                                container: true,
                                child: widget.child,
                              ),
                            ),
                    ),
                  ),
                ),
              ),

              // Handle hint only for panel mode
              if (!isBubble && t < 0.02)
                Positioned(
                  left: 6,
                  top: MediaQuery.of(context).padding.top + 12,
                  child: _HandleHint(color: cs.primary),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _EdgeDragRegion extends StatelessWidget {
  const _EdgeDragRegion({
    required this.child,
    required this.isOpen,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final Widget child;
  final bool isOpen;
  final GestureDragStartCallback onDragStart;
  final GestureDragUpdateCallback onDragUpdate;
  final GestureDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    // When closed: enable drag on a thin left-edge strip
    // When open: allow drag anywhere to close
    return Stack(
      children: [
        // Main content
        Positioned.fill(child: child),

        // Drag strip
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: isOpen ? MediaQuery.of(context).size.width : 24,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: onDragStart,
            onHorizontalDragUpdate: onDragUpdate,
            onHorizontalDragEnd: onDragEnd,
          ),
        ),
      ],
    );
  }
}

class _LiquidMenuPainter extends CustomPainter {
  _LiquidMenuPainter({
    required this.t,
    required this.dragX,
    required this.dragY,
    required this.dragging,
    required this.maxWidth,
    required this.curveDepth,
    required this.color,
  });

  final double t;
  final double dragX;
  final double dragY;
  final bool dragging;
  final double maxWidth;
  final double curveDepth;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    final baseW = lerpDouble(0, maxWidth, t)!;
    // Extra bulge when dragging for the “liquid” feel
    final extra = dragging ? (dragX.clamp(0, 120) * 0.5) : 0.0;
    final bulge = curveDepth * (0.6 + 0.4 * t) + extra;

    final cpY = dragY.clamp(0, size.height);
    final cpTopY = cpY * 0.3;
    final cpBottomY = size.height - (size.height - cpY) * 0.3;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(baseW, 0)
      // Top curve, pulling to the right with bulge
      ..cubicTo(
        baseW + bulge,
        cpTopY,
        baseW + bulge,
        cpBottomY,
        baseW,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidMenuPainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.dragX != dragX ||
        oldDelegate.dragY != dragY ||
        oldDelegate.dragging != dragging ||
        oldDelegate.maxWidth != maxWidth ||
        oldDelegate.curveDepth != curveDepth ||
        oldDelegate.color != color;
  }
}

class _FullScreenMenuContent extends StatelessWidget {
  const _FullScreenMenuContent({
    required this.header,
    required this.items,
    required this.onSelect,
    required this.progress,
  });

  final Widget header;
  final List<Widget> items;
  final void Function(int index)? onSelect;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Navigation menu',
      container: true,
      child: DefaultTextStyle(
        style: TextStyle(color: cs.onPrimary),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 24),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    // Start items a bit later so bubble cover appears first
                    final delay = 0.35 + (index * 0.06);
                    final localT = Curves.easeOut.transform(
                      ((progress - delay) / 0.65).clamp(0.0, 1.0),
                    );
                    final dy = lerpDouble(18, 0, localT)!;
                    final opacity = localT;

                    return Opacity(
                      opacity: opacity,
                      child: Transform.translate(
                        offset: Offset(0, dy),
                        child: _MenuItemWrapper(
                          index: index,
                          onTap: () => onSelect?.call(index),
                          child: items[index],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuContent extends StatelessWidget {
  const _MenuContent({
    required this.header,
    required this.items,
    required this.onSelect,
    required this.progress,
  });

  final Widget header;
  final List<Widget> items;
  final void Function(int index)? onSelect;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Semantics(
      label: 'Navigation menu',
      container: true,
      child: DefaultTextStyle(
        style: TextStyle(color: cs.onPrimary),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final delay = (index + 1) * 0.05;
                  final localT = Curves.easeOut.transform(
                    (progress - delay).clamp(0.0, 1.0),
                  );
                  final dx = lerpDouble(-24, 0, localT)!;
                  final opacity = localT;

                  return Opacity(
                    opacity: opacity,
                    child: Transform.translate(
                      offset: Offset(dx, 0),
                      child: _MenuItemWrapper(
                        index: index,
                        onTap: () => onSelect?.call(index),
                        child: items[index],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItemWrapper extends StatelessWidget {
  const _MenuItemWrapper({
    required this.index,
    required this.onTap,
    required this.child,
  });

  final int index;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashFactory: InkRipple.splashFactory,
        hoverColor: Colors.white.withOpacity(0.04),
        highlightColor: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: IconTheme(
            data: IconThemeData(color: cs.onPrimary),
            child: DefaultTextStyle(
              style: TextStyle(
                color: cs.onPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _BubbleRevealPainter extends CustomPainter {
  _BubbleRevealPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;

    final paint = Paint()..color = color;

    // Screen diagonal for coverage
    final diag = math.sqrt(size.width * size.width + size.height * size.height);

    // Bubble seeds anchored near left/middle to feel like originating from menu button
    final centers = <Offset>[
      Offset(size.width * 0.08, size.height * 0.20),
      Offset(size.width * 0.06, size.height * 0.50),
      Offset(size.width * 0.10, size.height * 0.80),
      Offset(size.width * 0.22, size.height * 0.35),
      Offset(size.width * 0.24, size.height * 0.65),
    ];

    // Stagger each bubble slightly so they bloom in sequence
    const delays = <double>[0.00, 0.06, 0.12, 0.18, 0.24];

    Path? combined;
    for (int i = 0; i < centers.length; i++) {
      final start = delays[i];
      final local = ((t - start) / (1.0 - start)).clamp(0.0, 1.0);
      if (local <= 0) continue;

      // Ease and size mix for variety
      final e = Curves.easeOutCubic.transform(local);
      final base = diag * (i < 3 ? 0.72 : 0.58); // larger for first three
      final r = lerpDouble(8, base, e)!;

      final path = Path()
        ..addOval(Rect.fromCircle(center: centers[i], radius: r));

      combined = (combined == null)
          ? path
          : Path.combine(PathOperation.union, combined, path);
    }

    if (combined != null) {
      canvas.drawPath(combined, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubbleRevealPainter old) {
    return old.t != t || old.color != color;
  }
}

class _HandleHint extends StatelessWidget {
  const _HandleHint({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = color;
    return Semantics(
      label: 'Open menu handle',
      button: true,
      child: Container(
        width: 8,
        height: 40,
        decoration: BoxDecoration(
          color: c.withOpacity(0.9),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}
