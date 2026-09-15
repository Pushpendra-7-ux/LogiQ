import 'package:flutter/material.dart';

class LoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;

  const LoadingSkeleton({
    super.key,
    this.width = double.infinity,
    this.height = 20,
    this.borderRadius = 8,
    this.baseColor,
  });

  @override
  State<LoadingSkeleton> createState() => _LoadingSkeletonState();
}

class _LoadingSkeletonState extends State<LoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _resolveBaseColor(BuildContext context) {
    if (widget.baseColor != null) return widget.baseColor!;
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? Colors.white : Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final base = _resolveBaseColor(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: base.withAlpha((_animation.value * 255).round()),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            LoadingSkeleton(height: 20, width: 200),
            SizedBox(height: 12),
            LoadingSkeleton(height: 16, width: 150),
            SizedBox(height: 8),
            LoadingSkeleton(height: 16),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonCard(),
    );
  }
}

class SkeletonCircle extends StatelessWidget {
  final double size;
  final Color? baseColor;

  const SkeletonCircle({super.key, this.size = 48, this.baseColor});

  @override
  Widget build(BuildContext context) {
    return LoadingSkeleton(
      width: size,
      height: size,
      borderRadius: size / 2,
      baseColor: baseColor,
    );
  }
}