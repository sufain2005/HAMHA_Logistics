import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/driver_theme.dart';
import '../../../core/models/truck_requirement_model.dart';
import '../../../core/services/driver_api_service.dart';

class DriverWorkSearchScreen extends StatefulWidget {
  final String initialSelectedState;

  const DriverWorkSearchScreen({
    super.key,
    this.initialSelectedState = 'Maharashtra',
  });

  @override
  State<DriverWorkSearchScreen> createState() => _DriverWorkSearchScreenState();
}

class _DriverWorkSearchScreenState extends State<DriverWorkSearchScreen> {
  late String _selectedState;
  String _selectedTruckType = 'all';
  bool _isLoading = false;
  List<TruckRequirementModel> _requirements = [];

  final List<String> _indianStates = [
    'Maharashtra',
    'Gujarat',
    'Karnataka',
    'Tamil Nadu',
    'Delhi NCR',
    'Telangana',
    'Uttar Pradesh',
    'West Bengal',
    'Rajasthan',
    'Madhya Pradesh',
  ];

  final Map<String, String> _truckTypeFilters = {
    'all': 'All Trucks',
    'box_truck': 'Box Truck',
    'mini_truck': 'Mini Truck / Ace',
    'heavy_freight': 'Heavy Multi-Axle',
    'van': 'Pharma Van',
  };

  @override
  void initState() {
    super.initState();
    _selectedState = widget.initialSelectedState;
    _fetchRequirements();
  }

  Future<void> _fetchRequirements() async {
    setState(() => _isLoading = true);
    final results = await DriverApiService().searchTruckRequirements(
      state: _selectedState,
      truckType: _selectedTruckType,
    );
    if (mounted) {
      setState(() {
        _requirements = results;
        _isLoading = false;
      });
    }
  }

  void _showOwnerContactModal(TruckRequirementModel req) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: DriverTheme.crispWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: DriverTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: DriverTheme.crimsonTint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.contacts, color: DriverTheme.crimsonRed, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        req.ownerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                      ),
                      Text(
                        req.ownerCompany,
                        style: const TextStyle(fontSize: 12, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: req.urgencyColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: req.urgencyColor),
                  ),
                  child: Text(
                    req.remainingTimeFormatted,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: req.urgencyColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Load Summary Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DriverTheme.warmCream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Target Load:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DriverTheme.textMuted)),
                      Flexible(
                        child: Text(
                          req.title,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Offered Rate:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DriverTheme.textMuted)),
                      Text(
                        '₹${req.offeredFare.toStringAsFixed(0)} INR',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Route Distance:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: DriverTheme.textMuted)),
                      Text(
                        '${req.pickupCity} ➔ ${req.dropoffCity} (${req.distanceKm.toInt()} km)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Direct Phone Call Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_in_talk, color: DriverTheme.statusOnline, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('DIRECT PHONE NUMBER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
                        Text(
                          req.ownerPhone,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: DriverTheme.textMuted),
                    tooltip: 'Copy Number',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: req.ownerPhone));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Phone number copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // WhatsApp Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DriverTheme.crispWhite,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DriverTheme.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('WHATSAPP FREIGHT DESK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted)),
                        Text(
                          req.ownerWhatsapp,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: DriverTheme.textMuted),
                    tooltip: 'Copy WhatsApp',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: req.ownerWhatsapp));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('WhatsApp number copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Direct Connect / Apply Button
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await DriverApiService().contactOwnerForRequirement(
                  req.id,
                  message: 'Driver applied for load: ${req.title}',
                );
                if (mounted) {
                  showDialog(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      backgroundColor: DriverTheme.crispWhite,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      title: const Row(
                        children: [
                          Icon(Icons.check_circle, color: DriverTheme.statusOnline, size: 24),
                          SizedBox(width: 8),
                          Text('Owner Contact Dispatched', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your vehicle profile and contact details were sent to ${req.ownerName} (${req.ownerCompany}).',
                            style: const TextStyle(fontSize: 13, color: DriverTheme.textDark),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'You may also call or WhatsApp the owner directly at:',
                            style: TextStyle(fontSize: 12, color: DriverTheme.textMuted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${req.ownerPhone} / ${req.ownerWhatsapp}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                          ),
                        ],
                      ),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          style: ElevatedButton.styleFrom(backgroundColor: DriverTheme.crimsonRed),
                          child: const Text('OKAY, GOT IT', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DriverTheme.crimsonRed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 16, color: DriverTheme.crispWhite),
                  SizedBox(width: 8),
                  Text('DISPATCH IN-APP LOAD APPLICATION', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DriverTheme.warmCream,
      appBar: AppBar(
        backgroundColor: DriverTheme.crispWhite,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: DriverTheme.deepBlack),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Search for Work in State',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: DriverTheme.deepBlack),
            onPressed: _fetchRequirements,
          ),
        ],
      ),
      body: Column(
        children: [
          // State Selector & Banner Header
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: DriverTheme.crispWhite,
              border: Border(bottom: BorderSide(color: DriverTheme.borderSubtle)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SELECT STATE TO SEARCH WORK:',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: DriverTheme.textMuted, letterSpacing: 0.6),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: DriverTheme.crimsonTint,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '3-DAY VALIDITY LOADS',
                        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // State Filter Horizontal Scroll
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _indianStates.map((state) {
                      final isSel = _selectedState.toLowerCase() == state.toLowerCase();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () {
                            setState(() => _selectedState = state);
                            _fetchRequirements();
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSel ? DriverTheme.crimsonRed : DriverTheme.warmCream,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? DriverTheme.crimsonRed : DriverTheme.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 13,
                                  color: isSel ? DriverTheme.crispWhite : DriverTheme.crimsonRed,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  state,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: isSel ? DriverTheme.crispWhite : DriverTheme.deepBlack,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Truck Type Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _truckTypeFilters.entries.map((entry) {
                      final isSel = _selectedTruckType == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: isSel,
                          onSelected: (val) {
                            if (val) {
                              setState(() => _selectedTruckType = entry.key);
                              _fetchRequirements();
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isSel ? DriverTheme.crispWhite : DriverTheme.textDark,
                          ),
                          selectedColor: DriverTheme.deepBlack,
                          backgroundColor: DriverTheme.warmCream,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(color: isSel ? DriverTheme.deepBlack : DriverTheme.borderSubtle),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Requirement Feed / Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: DriverTheme.crimsonRed))
                : _requirements.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.search_off, size: 52, color: DriverTheme.textMuted),
                              const SizedBox(height: 14),
                              Text(
                                'No open truck requirements in $_selectedState right now.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Owners post loads with 3-day validity. Switch states or check back soon.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: DriverTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(18),
                        itemCount: _requirements.length,
                        itemBuilder: (context, index) {
                          final req = _requirements[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: DriverTheme.crispWhite,
                            elevation: 1.5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: const BorderSide(color: DriverTheme.borderSubtle, width: 1.2),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top Banner: Urgency Countdown & Truck Type
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: req.urgencyColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: req.urgencyColor),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.hourglass_bottom, size: 13, color: req.urgencyColor),
                                            const SizedBox(width: 4),
                                            Text(
                                              '⏳ ${req.remainingTimeFormatted} (3-DAY POST)',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                                color: req.urgencyColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: DriverTheme.deepBlack,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(req.truckIcon, size: 12, color: DriverTheme.crispWhite),
                                            const SizedBox(width: 4),
                                            Text(
                                              req.truckTypeDisplayName.toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w900,
                                                color: DriverTheme.crispWhite,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Title & Owner
                                  Text(
                                    req.title,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: DriverTheme.deepBlack),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.business, size: 13, color: DriverTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${req.ownerName} • ${req.ownerCompany}',
                                        style: const TextStyle(fontSize: 11, color: DriverTheme.textMuted, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 14),

                                  // Route Visualizer
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: DriverTheme.warmCream,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: DriverTheme.borderSubtle),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.trip_origin, size: 14, color: DriverTheme.crimsonRed),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'PICKUP (${req.pickupState.toUpperCase()})',
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: DriverTheme.textMuted),
                                                  ),
                                                  Text(
                                                    req.pickupAddress,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6.0),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(width: 1.5, height: 16, color: DriverTheme.borderSubtle),
                                          ),
                                        ),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Icon(Icons.location_on, size: 14, color: DriverTheme.deepBlack),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'DROP-OFF (${req.dropoffState.toUpperCase()})',
                                                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: DriverTheme.textMuted),
                                                  ),
                                                  Text(
                                                    req.dropoffAddress,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DriverTheme.deepBlack),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 14),

                                  // Cargo & Fare Summary
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'CARGO & TONNAGE',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${req.cargoType} • ${req.weightTons} T',
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: DriverTheme.textDark),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'OFFERED FARE',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: DriverTheme.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '₹${req.offeredFare.toStringAsFixed(0)}',
                                            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: DriverTheme.crimsonRed),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(color: DriverTheme.borderSubtle, height: 1),
                                  const SizedBox(height: 12),

                                  // Action Bar: Contact Owner
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _showOwnerContactModal(req),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: DriverTheme.deepBlack,
                                            foregroundColor: DriverTheme.crispWhite,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          icon: const Icon(Icons.phone_in_talk, size: 16),
                                          label: const Text('CONTACT OWNER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

