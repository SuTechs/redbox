import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'pocket_theme.dart';

PageRouteBuilder<T> pocketRoute<T>(BuildContext context, Widget page) =>
    PageRouteBuilder<T>(
      transitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
      reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
    );

class PocketPage extends StatelessWidget {
  const PocketPage({
    super.key,
    required this.child,
    required this.minimumHeight,
  });
  final Widget child;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(constraints.maxHeight, minimumHeight),
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 25),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PocketButton extends StatefulWidget {
  const PocketButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.secondary = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool secondary;
  @override
  State<PocketButton> createState() => _PocketButtonState();
}

class _PocketButtonState extends State<PocketButton> {
  bool _pressed = false;
  @override
  Widget build(BuildContext context) {
    final face = widget.secondary ? PocketColors.tile : PocketColors.red;
    final depth = widget.secondary
        ? PocketColors.tileDepth
        : PocketColors.redDepth;
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Stack(
        children: [
          Positioned.fill(
            top: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: depth,
                borderRadius: BorderRadius.circular(17),
              ),
            ),
          ),
          AnimatedPadding(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 90),
            padding: EdgeInsets.only(
              top: _pressed ? 2 : 0,
              bottom: _pressed ? 2 : 4,
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onPressed,
                style: TextButton.styleFrom(
                  backgroundColor: face,
                  foregroundColor: widget.secondary
                      ? PocketColors.ink
                      : PocketColors.buttonInk,
                  minimumSize: const Size(48, 56),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 17,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(widget.label, textAlign: TextAlign.center),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 10),
                      Icon(widget.icon, size: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PocketWordmark extends StatelessWidget {
  const PocketWordmark({super.key});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Transform.rotate(
        angle: -.15,
        child: Container(
          width: 15,
          height: 15,
          decoration: BoxDecoration(
            color: PocketColors.red,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Red Box',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: PocketColors.ink,
          letterSpacing: -.4,
        ),
      ),
    ],
  );
}

class SquareMascot extends StatelessWidget {
  const SquareMascot({super.key, this.size = 108});
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: -.155,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: PocketColors.red,
          borderRadius: BorderRadius.circular(size * .22),
          boxShadow: [
            BoxShadow(
              color: PocketColors.redDepth,
              offset: Offset(0, size * .075),
            ),
            BoxShadow(
              color: const Color(0xFFA44831).withValues(alpha: .13),
              blurRadius: 25,
              offset: const Offset(0, 19),
            ),
          ],
        ),
        child: CustomPaint(painter: _MascotFace()),
      ),
    ),
  );
}

class _MascotFace extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 104, size.height / 104);
    final paint = Paint()..color = const Color(0xFF642E28);
    canvas.drawOval(const Rect.fromLTWH(32, 42, 6, 10), paint);
    canvas.drawOval(const Rect.fromLTWH(61, 42, 6, 10), paint);
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      const Rect.fromLTWH(44, 52, 17, 16),
      0,
      math.pi,
      false,
      paint,
    );
    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFFFB0A7).withValues(alpha: .48);
    canvas.drawOval(const Rect.fromLTWH(23, 55, 12, 6), paint);
    canvas.drawOval(const Rect.fromLTWH(71, 55, 12, 6), paint);
    paint.color = const Color(0xFFFFF8EB).withValues(alpha: .25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 12, 43, 7),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotFace oldDelegate) => false;
}

class HomeIllustration extends StatelessWidget {
  const HomeIllustration({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 217,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const SquareMascot(),
        Positioned(
          left: 27,
          top: 38,
          child: _FloatingSquare(size: 28, angle: .25),
        ),
        Positioned(
          right: 16,
          bottom: 32,
          child: _FloatingSquare(size: 38, angle: -.24),
        ),
        Positioned(
          left: 56,
          bottom: 20,
          child: _FloatingSquare(size: 17, angle: -.12),
        ),
      ],
    ),
  );
}

class _FloatingSquare extends StatelessWidget {
  const _FloatingSquare({required this.size, required this.angle});
  final double size;
  final double angle;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: PocketColors.tile,
          borderRadius: BorderRadius.circular(size * .24),
          boxShadow: const [
            BoxShadow(color: PocketColors.tileDepth, offset: Offset(0, 3)),
          ],
        ),
      ),
    ),
  );
}

class PocketTile extends StatelessWidget {
  const PocketTile({
    super.key,
    required this.id,
    required this.red,
    required this.selected,
    required this.onTap,
    required this.reducedMotion,
    required this.symbolCue,
    this.glow = 0,
    this.cornerRadius = 18,
  });
  final int id;
  final bool red;
  final bool selected;
  final VoidCallback? onTap;
  final bool reducedMotion;
  final bool symbolCue;
  final double glow;
  final double cornerRadius;
  @override
  Widget build(BuildContext context) {
    final color = red
        ? Color.lerp(PocketColors.red, const Color(0xFFFF8C79), glow * .18)!
        : PocketColors.tile;
    final radius = BorderRadius.circular(cornerRadius);
    return Semantics(
      label:
          'Box ${id + 1}${red ? ', red' : ''}${selected ? ', selected' : ''}',
      button: true,
      enabled: onTap != null,
      selected: selected,
      onTap: onTap,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: reducedMotion
              ? Duration.zero
              : const Duration(milliseconds: 260),
          transform: Matrix4.translationValues(0, selected ? 2 : 0, 0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: red ? PocketColors.redDepth : PocketColors.tileDepth,
                offset: Offset(0, selected ? 4 : 6),
              ),
              if (red && glow > 0)
                BoxShadow(
                  color: PocketColors.red.withValues(alpha: glow * .16),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: InkWell(
              key: ValueKey('box-$id'),
              onTap: onTap,
              borderRadius: radius,
              child: Center(
                child: red && symbolCue
                    ? const Icon(
                        Icons.circle_outlined,
                        color: PocketColors.ink,
                        size: 23,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PocketSheet extends StatelessWidget {
  const PocketSheet({
    super.key,
    required this.title,
    required this.children,
    this.close = true,
  });
  final String title;
  final List<Widget> children;
  final bool close;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 27),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: PocketType.title.copyWith(fontSize: 27),
                  ),
                ),
                if (close)
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    ),
  );
}
