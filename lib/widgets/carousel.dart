import 'dart:async';

import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import 'common.dart';

/// Auto-rotating hero carousel with pagination dots.
class HeroCarousel extends StatefulWidget {
  final List<SlideItem> slides;
  final double height;
  final double radius;
  final Duration interval;
  final EdgeInsets padding;

  const HeroCarousel({
    super.key,
    required this.slides,
    this.height = 152,
    this.radius = 18,
    this.interval = const Duration(milliseconds: 3500),
    this.padding = const EdgeInsets.fromLTRB(14, 10, 14, 4),
  });

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _ctrl;
  Timer? _timer;
  int _idx = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    if (widget.slides.length > 1) {
      _timer = Timer.periodic(widget.interval, (_) {
        if (!mounted || !_ctrl.hasClients) return;
        final next = (_idx + 1) % widget.slides.length;
        _ctrl.animateToPage(next,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.p;
    return Padding(
      padding: widget.padding,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: p.shadowMd,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.radius),
          child: Stack(
            children: [
              PageView.builder(
                controller: _ctrl,
                itemCount: widget.slides.length,
                onPageChanged: (i) => setState(() => _idx = i),
                itemBuilder: (_, i) => _Slide(slide: widget.slides[i]),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < widget.slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _idx ? 16 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: i == _idx
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  final SlideItem slide;
  const _Slide({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.grad,
        ),
      ),
      child: Stack(
        children: [
          // Seed placeholder underlay (matches prototype)
          Positioned.fill(
            child: SeedPlaceholder(seed: slide.seed, radius: 0),
          ),
          // Decorative bubbles
          Positioned(
            top: -30,
            right: -20,
            child: _bubble(140, 0.12),
          ),
          Positioned(
            bottom: -50,
            left: -20,
            child: _bubble(130, 0.08),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                            color: Color(0x4D000000),
                            blurRadius: 8,
                            offset: Offset(0, 2))
                      ],
                    ),
                  ),
                  if (slide.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      slide.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        letterSpacing: 2,
                        shadows: const [
                          Shadow(
                              color: Color(0x4D000000),
                              blurRadius: 4,
                              offset: Offset(0, 1))
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}
