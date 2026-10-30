import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../../core/services/driver_api_service.dart';

class DispatchOfferModal extends StatefulWidget {
  final DispatchOfferModel offer;
  final ValueChanged<DispatchOfferModel> onAccept;
  final VoidCallback onDecline;

  const DispatchOfferModal({
    super.key,
    required this.offer,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<DispatchOfferModal> createState() => _DispatchOfferModalState();
}

class _DispatchOfferModalState extends State<DispatchOfferModal> with SingleTickerProviderStateMixin {
  late int _secondsRemaining;
  Timer? _countdownTimer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isAccepting = false;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.offer.expiresInSeconds;

    // Siren pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initial alert vibration / haptic
    HapticFeedback.heavyImpact();

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        if (mounted) {
          setState(() => _secondsRemaining--);
          if (_secondsRemaining % 3 == 0) {
            HapticFeedback.mediumImpact();
          }
        }
      } else {
        timer.cancel();
        _handleDecline(isExpired: true);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleAccept() async {
    _countdownTimer?.cancel();
    setState(() => _isAccepting = true);

    try {
      await DriverApiService().acceptOrder(orderId: widget.offer.id);
      if (!mounted) return;
      widget.onAccept(widget.offer);
    } catch (_) {
      if (!mounted) return;
      widget.onAccept(widget.offer);
    }
  }

  void _handleDecline({bool isExpired = false}) {
    _countdownTimer?.cancel();
    DriverApiService().declineOrder(orderId: widget.offer.id);
    widget.onDecline();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _secondsRemaining / widget.offer.expiresInSeconds;

    return Container(
      decoration: const BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 28,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ALERT BANNER WITH COUNTDOWN & SIREN
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: DriverTheme.deepBlack,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: const BoxDecoration(
                          color: DriverTheme.crimsonRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.flash_on, color: DriverTheme.crispWhite, size: 16),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INCOMING DISPATCH OFFER',
                          style: TextStyle(
                            color: DriverTheme.crispWhite,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          widget.offer.orderCode,
                          style: const TextStyle(
                            color: DriverTheme.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // 15-Second Circular Countdown Ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 42,
                      height: 42,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: DriverTheme.surfaceBlack,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _secondsRemaining > 5 ? DriverTheme.crimsonRed : Colors.amber,
                        ),
                        strokeWidth: 3.5,
                      ),
                    ),
                    Text(
                      '${_secondsRemaining}s',
                      style: const TextStyle(
                        color: DriverTheme.crispWhite,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 2. MAIN OFFER CONTENT
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Payout and Key Stats Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: DriverTheme.warmCream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GUARANTEED NET PAYOUT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: DriverTheme.textMuted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${widget.offer.payoutAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: DriverTheme.crimsonRed,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Includes GST & Fuel Tolls',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: DriverTheme.textDark,
                            ),
                          ),
                        ],
                      ),

                      // Distance & ETA Badge
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: DriverTheme.crispWhite,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: DriverTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.route, color: DriverTheme.deepBlack, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  '${widget.offer.distanceKm} km',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '~${widget.offer.estimatedDurationMin} mins transit',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: DriverTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Cargo Details Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: DriverTheme.crimsonTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverTheme.crimsonRed.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined, size: 16, color: DriverTheme.crimsonRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.offer.cargoType} • ${widget.offer.weightKg} kg',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: DriverTheme.crimsonDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Pickup & Drop-off Route Map Points
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: DriverTheme.crispWhite,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      // Pickup
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.trip_origin, color: DriverTheme.crimsonRed, size: 18),
                              Container(width: 1.5, height: 28, color: DriverTheme.borderSubtle),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PICKUP WAREHOUSE',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: DriverTheme.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.offer.pickupAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Drop-off
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: DriverTheme.deepBlack, size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DELIVERY DESTINATION',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: DriverTheme.textMuted,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.offer.dropoffAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. ACTIONS: ACCEPT & REJECT BUTTONS
                Row(
                  children: [
                    // Reject / Pass button
                    Expanded(
                      flex: 4,
                      child: OutlinedButton(
                        onPressed: _isAccepting ? null : () => _handleDecline(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          foregroundColor: DriverTheme.textMuted,
                          side: const BorderSide(color: DriverTheme.borderSubtle, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          'PASS / DECLINE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Large Accept Button
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        onPressed: _isAccepting ? null : _handleAccept,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DriverTheme.crimsonRed,
                          foregroundColor: DriverTheme.crispWhite,
                          minimumSize: const Size.fromHeight(56),
                          elevation: 5,
                          shadowColor: DriverTheme.crimsonRed.withAlpha(100),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isAccepting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(color: DriverTheme.crispWhite, strokeWidth: 2.5),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_outline, size: 20),
                                  const SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'ACCEPT (₹${widget.offer.payoutAmount.toStringAsFixed(0)})',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

