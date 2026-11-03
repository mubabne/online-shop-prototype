import 'package:flutter/material.dart';

/// Жагсаалтын элементүүдийг дарааллаар нь (stagger) гулсуулж, тодруулж гаргана.
/// Timer ашиглахгүй — саатлыг Interval curve-ээр гаргадаг.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = const Offset(0, 0.15),
  });

  final Widget child;
  final int index;
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    final step = widget.index.clamp(0, 10);
    const base = 420;
    const delay = 60;
    final total = base + step * delay;
    _ctrl = AnimationController(
        vsync: this, duration: Duration(milliseconds: total))
      ..forward();
    _curve = CurvedAnimation(
      parent: _ctrl,
      curve: Interval(step * delay / total, 1, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween(begin: widget.offset, end: Offset.zero).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Тоог 0-ээс эцсийн утга хүртэл тоолж харуулна.
class CountUpText extends StatelessWidget {
  const CountUpText({
    super.key,
    required this.value,
    this.format,
    this.style,
  });

  final num value;
  final String Function(num)? format;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text(
        format?.call(v) ?? v.round().toString(),
        style: style,
      ),
    );
  }
}

/// Дарахад бага зэрэг жижгэрч "хөдөлгөөнтэй" мэдрэмж өгнө.
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

/// Утга өөрчлөгдөх бүрд "үсрэх" анимэйшн (сагсны тоо гэх мэт).
class BumpOnChange extends StatelessWidget {
  const BumpOnChange({super.key, required this.value, required this.child});

  final Object value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (c, a) => ScaleTransition(
        scale: TweenSequence([
          TweenSequenceItem(tween: Tween(begin: 0.6, end: 1.25), weight: 60),
          TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 40),
        ]).animate(a),
        child: c,
      ),
      child: KeyedSubtree(key: ValueKey(value), child: child),
    );
  }
}
