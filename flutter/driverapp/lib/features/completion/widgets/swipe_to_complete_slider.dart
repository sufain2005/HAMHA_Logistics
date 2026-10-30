import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';

class SwipeToCompleteSlider extends StatefulWidget {
  final VoidCallback onComplete;
  final String label;
  final bool isEnabled;

  const SwipeToCompleteSlider({
    super.key,
    required this.onComplete,
    this.label = 'SWIPE TO COMPLETE DELIVERY',
    this.isEnabled = true,
  });

  @override
  State<SwipeToCompleteSlider> createState() => _SwipeToCompleteSliderState();
}

class _SwipeToCompleteSliderState extends State<SwipeToCompleteSlider> with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _isCompleted = false;
  late AnimationController _resetController;
  late Animation<double> _resetAnimation;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (!widget.isEnabled || _isCompleted) return;

    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });

    // Check if dragged far enough to complete
    if (_dragPosition >= maxDrag * 0.88 && !_isCompleted) {
      _isCompleted = true;
      HapticFeedback.heavyImpact();
      widget.onComplete();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details, double maxDrag) {
    if (_isCompleted) return;

    // Animate back to start if not completed
    final start = _dragPosition;
    _resetAnimation = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    )..addListener(() {
        setState(() {
          _dragPosition = _resetAnimation.value;
        });
      });

    _resetController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    const double height = 64.0;
    const double thumbWidth = 60.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbWidth - 8.0;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: widget.isEnabled ? DriverTheme.deepBlack : DriverTheme.warmCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isEnabled ? DriverTheme.crimsonRed.withAlpha(90) : DriverTheme.borderSubtle,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Prompt Text
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(left: 36.0, right: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: widget.isEnabled ? DriverTheme.crispWhite : DriverTheme.textMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.double_arrow,
                        color: widget.isEnabled ? DriverTheme.crimsonRed : DriverTheme.textMuted,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              // Sliding Thumb
              Positioned(
                left: 4.0 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onHorizontalDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onHorizontalDragEnd(details, maxDrag),
                  child: Container(
                    width: thumbWidth,
                    height: height - 8.0,
                    decoration: BoxDecoration(
                      color: DriverTheme.crimsonRed,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: DriverTheme.crimsonRed.withAlpha(120),
                          blurRadius: 10,
                          offset: const Offset(2, 0),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: DriverTheme.crispWhite,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
