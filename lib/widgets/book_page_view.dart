import 'dart:math';
import 'package:flutter/material.dart';

/// A 3D Book Page Flip container that turns pages like a real book
class BookPageView extends StatefulWidget {
  final List<Widget> pages;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const BookPageView({
    super.key,
    required this.pages,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  State<BookPageView> createState() => _BookPageViewState();
}

class _BookPageViewState extends State<BookPageView> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.pageController,
      builder: (context, child) {
        double currentPage = 0.0;
        if (widget.pageController.hasClients && widget.pageController.position.haveDimensions) {
          currentPage = widget.pageController.page ?? widget.pageController.initialPage.toDouble();
        } else {
          currentPage = widget.pageController.initialPage.toDouble();
        }

        return Stack(
          children: [
            // Spine Shadow Background (gives depth like a book fold)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.03),
                      Colors.black.withValues(alpha: 0.10),
                      Colors.black.withValues(alpha: 0.03),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
            ),

            PageView.builder(
              controller: widget.pageController,
              onPageChanged: widget.onPageChanged,
              itemCount: widget.pages.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final double position = index - currentPage;
                return _build3DBookPage(widget.pages[index], position);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _build3DBookPage(Widget pageChild, double position) {
    // If page is completely off screen, render static child
    if (position.abs() >= 1.0) {
      return pageChild;
    }

    // Perspective matrix for 3D book page curl
    final matrix = Matrix4.identity()
      ..setEntry(3, 2, 0.0014); // Perspective strength

    if (position > 0) {
      // Page coming from right -> flipping left
      final double angle = -position * (pi / 2.2);
      matrix.rotateY(angle);

      return Transform(
        transform: matrix,
        alignment: Alignment.centerLeft,
        child: Stack(
          children: [
            pageChild,
            // Inner shadow simulating page fold darkness
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withValues(alpha: (0.35 * position).clamp(0.0, 0.5)),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Page exiting to left -> rotating around right spine
      final double angle = -position * (pi / 2.2);
      matrix.rotateY(angle);

      return Transform(
        transform: matrix,
        alignment: Alignment.centerRight,
        child: Stack(
          children: [
            pageChild,
            // Outer shadow overlay
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: (0.35 * (-position)).clamp(0.0, 0.5)),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
