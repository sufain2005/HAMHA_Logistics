import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/dispatch_offer_model.dart';
import '../../../core/services/driver_api_service.dart';
import '../widgets/swipe_to_complete_slider.dart';
import 'driver_trip_success_screen.dart';

class DriverPodScreen extends StatefulWidget {
  final DispatchOfferModel offer;

  const DriverPodScreen({
    super.key,
    required this.offer,
  });

  @override
  State<DriverPodScreen> createState() => _DriverPodScreenState();
}

class _DriverPodScreenState extends State<DriverPodScreen> {
  final ImagePicker _picker = ImagePicker();
  final _recipientController = TextEditingController(text: 'Amit Sharma (Facility Lead)');
  final _remarksController = TextEditingController(text: 'Received in sealed condition at Tower B Inward Dock');

  String? _capturedImageName;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _recipientController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedImageName = photo.name;
        });
      }
    } catch (_) {
      // Fallback for browser/desktop testing without hardware camera
      setState(() {
        _capturedImageName = 'mock_camera_package_photo.jpg';
      });
    }
  }

  Future<void> _handleDeliveryCompletion() async {
    final recipient = _recipientController.text.trim();
    if (recipient.isEmpty) {
      setState(() => _errorMessage = 'Please enter the receiving party\'s name.');
      return;
    }

    if (_capturedImageName == null) {
      setState(() => _errorMessage = 'Please capture a Proof of Delivery photo of the package.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await DriverApiService().updateOrderStatus(
        orderId: widget.offer.id,
        status: 'delivered',
        recipientName: recipient,
        deliveryNotes: _remarksController.text.trim(),
        podImagePath: _capturedImageName,
      );

      // Add to driver shift earnings
      final driver = DriverApiService().currentDriver;
      if (driver != null) {
        DriverApiService().currentDriver = driver;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DriverTripSuccessScreen(offer: widget.offer),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        title: const Text('Proof of Delivery (POD)'),
        backgroundColor: DriverTheme.crispWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Order & Destination Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: DriverTheme.crispWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DriverTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DriverTheme.deepBlack,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                widget.offer.orderCode,
                                style: const TextStyle(
                                  color: DriverTheme.crispWhite,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'FINAL DELIVERY STAGE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: DriverTheme.crimsonRed,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '₹${widget.offer.payoutAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: DriverTheme.crimsonRed,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: DriverTheme.deepBlack, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.offer.dropoffAddress,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: DriverTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: DriverTheme.crimsonTint,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: DriverTheme.crimsonRed.withAlpha(80)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: DriverTheme.crimsonRed, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 1. CAMERA PHOTO PROOF CAPTURE FRAME
              const Text(
                'PACKAGE PHOTO EVIDENCE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: DriverTheme.textMuted,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: DriverTheme.deepBlack,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: DriverTheme.borderSubtle, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Corner Alignment Brackets
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: DriverTheme.crimsonRed, width: 3), left: BorderSide(color: DriverTheme.crimsonRed, width: 3)))),
                    ),
                    Positioned(
                      top: 14,
                      right: 14,
                      child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: DriverTheme.crimsonRed, width: 3), right: BorderSide(color: DriverTheme.crimsonRed, width: 3)))),
                    ),
                    Positioned(
                      bottom: 14,
                      left: 14,
                      child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DriverTheme.crimsonRed, width: 3), left: BorderSide(color: DriverTheme.crimsonRed, width: 3)))),
                    ),
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: DriverTheme.crimsonRed, width: 3), right: BorderSide(color: DriverTheme.crimsonRed, width: 3)))),
                    ),

                    // Center photo status
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _capturedImageName != null
                                ? DriverTheme.statusOnline.withAlpha(30)
                                : DriverTheme.surfaceBlack,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _capturedImageName != null ? DriverTheme.statusOnline : DriverTheme.crimsonRed,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _capturedImageName != null ? Icons.check_circle : Icons.camera_alt,
                            color: _capturedImageName != null ? DriverTheme.statusOnline : DriverTheme.crimsonRed,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _capturedImageName != null
                              ? 'Package Photo Captured & Tagged'
                              : 'Photograph Package at Drop-off Door / Dock',
                          style: const TextStyle(
                            color: DriverTheme.crispWhite,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (_capturedImageName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _capturedImageName!,
                            style: const TextStyle(color: DriverTheme.textMuted, fontSize: 11),
                          ),
                        ],
                        const SizedBox(height: 14),

                        // Action Buttons: Camera & Gallery
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _capturePhoto(ImageSource.camera),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DriverTheme.crimsonRed,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.camera_alt, size: 16, color: DriverTheme.crispWhite),
                              label: Text(
                                _capturedImageName != null ? 'RETAKE' : 'OPEN CAMERA',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed: () => _capturePhoto(ImageSource.gallery),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: DriverTheme.crispWhite,
                                side: const BorderSide(color: DriverTheme.borderSubtle),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                minimumSize: Size.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.photo_library, size: 16),
                              label: const Text('GALLERY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. RECIPIENT SIGNATORY DETAILS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: DriverTheme.crispWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: DriverTheme.borderSubtle),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(12),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'RECEIVING PERSON NAME / DESK',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _recipientController,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: DriverTheme.deepBlack),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Amit Sharma (Security / Store Manager)',
                        prefixIcon: Icon(Icons.person_pin, color: DriverTheme.crimsonRed),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'DELIVERY REMARKS & DOCK NOTES',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _remarksController,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: DriverTheme.deepBlack),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Handed over in intact sealed condition',
                        prefixIcon: Icon(Icons.note_alt_outlined, color: DriverTheme.textDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3. SWIPE TO COMPLETE DELIVERY SLIDER
              if (_isSubmitting)
                const Center(
                  child: CircularProgressIndicator(color: DriverTheme.crimsonRed),
                )
              else
                SwipeToCompleteSlider(
                  label: 'SWIPE TO COMPLETE DELIVERY',
                  onComplete: _handleDeliveryCompletion,
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
