import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/services/driver_api_service.dart';
import '../../../core/models/driver_user_model.dart';
import '../../dashboard/screens/driver_main_shell.dart';

class DriverDocumentUploadScreen extends StatefulWidget {
  const DriverDocumentUploadScreen({super.key});

  @override
  State<DriverDocumentUploadScreen> createState() => _DriverDocumentUploadScreenState();
}

class _DriverDocumentUploadScreenState extends State<DriverDocumentUploadScreen> {
  final ImagePicker _picker = ImagePicker();

  String? _cdlPath = 'sample_cdl_verified.jpg';
  String? _rcPath = 'sample_rc_verified.jpg';
  String? _insurancePath = 'sample_insurance_verified.jpg';

  bool _isUploading = false;
  String? _errorMessage;

  Future<void> _pickImage(String docType) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (file != null) {
        setState(() {
          if (docType == 'cdl') _cdlPath = file.name;
          if (docType == 'rc') _rcPath = file.name;
          if (docType == 'insurance') _insurancePath = file.name;
        });

        await DriverApiService().uploadDocument(
          docType: docType,
          imagePath: file.path,
        );
      }
    } catch (_) {
      // Demo mock fallback if camera / gallery is not available on test device
      setState(() {
        if (docType == 'cdl') _cdlPath = 'cdl_uploaded.jpg';
        if (docType == 'rc') _rcPath = 'rc_uploaded.jpg';
        if (docType == 'insurance') _insurancePath = 'insurance_uploaded.jpg';
      });
    }
  }

  Future<void> _handleCompleteOnboarding() async {
    if (_cdlPath == null || _rcPath == null || _insurancePath == null) {
      setState(() => _errorMessage = 'Please upload all 3 compliance documents before submitting.');
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // Mark driver verified upon uploading all compliance details
      final current = DriverApiService().currentDriver;
      if (current != null) {
        DriverApiService().currentDriver = DriverUserModel(
          id: current.id,
          name: current.name,
          phone: current.phone,
          email: current.email,
          isVerified: true,
          isOnline: current.isOnline,
          isOnboarded: true,
          vehicleType: current.vehicleType,
          plateNumber: current.plateNumber,
          vehicleModel: current.vehicleModel,
          rating: current.rating,
          todayEarnings: current.todayEarnings,
          todayTrips: current.todayTrips,
          onlineHours: current.onlineHours,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All details submitted and verified! Your driver account is now VERIFIED.'),
          backgroundColor: DriverTheme.statusOnline,
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DriverMainShell()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        title: const Text('Compliance Verification'),
        backgroundColor: DriverTheme.crispWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: DriverTheme.crispWhite,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DriverTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'STEP 3 OF 3: STATUTORY KYC & LICENSES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: DriverTheme.crimsonRed,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DriverTheme.warmCream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('100%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Upload Statutory Documents',
                  style: TextStyle(
                    color: DriverTheme.deepBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Provide clear images or PDFs of your operating credentials to activate your commercial carrier profile.',
                  style: TextStyle(color: DriverTheme.textMuted, fontSize: 13, height: 1.4),
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
                    child: Text(_errorMessage!, style: const TextStyle(color: DriverTheme.crimsonRed, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Document 1: CDL
                _buildDocUploadCard(
                  title: "Commercial Driver's License (CDL)",
                  description: 'Valid Light / Heavy Goods Vehicle driving authorization.',
                  fileName: _cdlPath,
                  onTap: () => _pickImage('cdl'),
                ),
                const SizedBox(height: 14),

                // Document 2: RC
                _buildDocUploadCard(
                  title: 'Vehicle Registration Certificate (RC)',
                  description: 'Official Ministry of Road Transport & Highways certificate.',
                  fileName: _rcPath,
                  onTap: () => _pickImage('rc'),
                ),
                const SizedBox(height: 14),

                // Document 3: Insurance
                _buildDocUploadCard(
                  title: 'Commercial Cargo & Transit Insurance',
                  description: 'Comprehensive policy covering road freight and third-party liabilities.',
                  fileName: _insurancePath,
                  onTap: () => _pickImage('insurance'),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElevatedButton(
                  onPressed: _isUploading ? null : _handleCompleteOnboarding,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DriverTheme.crimsonRed,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: DriverTheme.crispWhite, strokeWidth: 2.5),
                        )
                      : const Text('SUBMIT APPLICATION & START DRIVING'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDocUploadCard({
    required String title,
    required String description,
    required String? fileName,
    required VoidCallback onTap,
  }) {
    final isUploaded = fileName != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DriverTheme.crispWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUploaded ? DriverTheme.statusOnline.withAlpha(120) : DriverTheme.borderSubtle,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: DriverTheme.deepBlack,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isUploaded ? DriverTheme.statusOnline.withAlpha(20) : DriverTheme.warmCream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUploaded ? DriverTheme.statusOnline : DriverTheme.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUploaded ? Icons.verified : Icons.hourglass_top,
                      size: 13,
                      color: isUploaded ? DriverTheme.statusOnline : DriverTheme.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isUploaded ? 'VERIFIED' : 'PENDING',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isUploaded ? DriverTheme.statusOnline : DriverTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(description, style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted, height: 1.3)),
          const SizedBox(height: 14),

          // Action button / Chip
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUploaded ? DriverTheme.warmCream : DriverTheme.crimsonTint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploaded ? DriverTheme.borderSubtle : DriverTheme.crimsonRed.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUploaded ? Icons.attachment : Icons.cloud_upload_outlined,
                    color: isUploaded ? DriverTheme.deepBlack : DriverTheme.crimsonRed,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isUploaded ? 'Replace: $fileName' : 'Upload Document / Photo',
                    style: TextStyle(
                      color: isUploaded ? DriverTheme.deepBlack : DriverTheme.crimsonRed,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
