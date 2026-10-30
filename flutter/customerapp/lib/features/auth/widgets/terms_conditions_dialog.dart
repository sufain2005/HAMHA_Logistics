import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class TermsConditionsDialog extends StatelessWidget {
  const TermsConditionsDialog({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TermsConditionsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: HamhaTheme.crispWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              // Top drag indicator
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 14, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: HamhaTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: HamhaTheme.deepBlack,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.gavel, color: HamhaTheme.crispWhite, size: 18),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TERMS OF SERVICE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: HamhaTheme.deepBlack,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              'HAMHA Freight & Supply Chain Agreement',
                              style: TextStyle(fontSize: 12, color: HamhaTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: HamhaTheme.deepBlack),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(color: HamhaTheme.borderSubtle, height: 1),

              // Contract Body
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: HamhaTheme.warmCream,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: HamhaTheme.borderSubtle),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: HamhaTheme.crimsonRed, size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Effective October 2026. Governs nationwide freight operations, carrier responsibilities, and customer cargo rights.',
                              style: TextStyle(color: HamhaTheme.textDark, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _buildSection(
                      number: '1.0',
                      title: 'Acceptance of Freight Services & Roles',
                      content:
                          'By accessing or using the HAMHA Logistics SaaS platform as a Shipper, Consignee, or Carrier Partner, you enter into a legally binding contract with HAMHA Logistics LLC. All carriage, dispatch, route optimization, and cargo handling services are executed in accordance with Federal Motor Carrier Safety Administration (FMCSA) and applicable commercial carriage standards.',
                    ),
                    _buildSection(
                      number: '2.0',
                      title: 'Cargo Declarations & Prohibited Goods',
                      content:
                          'The Shipper guarantees that all cargo submitted through the platform is accurately declared by gross weight (kg), dimensions, packaging integrity, and commodity description.\n\nPROHIBITED ARTICLES:\n• Class 1 Explosives, toxic gasses, and unlicensed radioactive material.\n• Unmanifested hazardous chemicals, bio-waste, and contraband.\n• Live animals without certified temperature-controlled transit credentials.\nAny shipment containing undeclared hazardous goods is subject to immediate rejection, carrier detention fees, and civil forfeiture.',
                    ),
                    _buildSection(
                      number: '3.0',
                      title: 'Live Geolocation & Telemetry Consent',
                      content:
                          'HAMHA utilizes Mapbox, PostGIS, and real-time Socket.io telemetry. Shippers, drivers, and fleet owners explicitly consent to continuous GPS coordinate capture, breadcrumb archiving, and route velocity analysis during active transit. Location data is retained strictly for transit security, chain of custody verification, and digital dispute audit trails.',
                    ),
                    _buildSection(
                      number: '4.0',
                      title: 'Dynamic Pricing, Tariffs & Cancellation',
                      content:
                          'Quotations generated by the HAMHA Cost Calculator represent commercial estimates derived from spherical great-circle coordinates, route algorithms, cargo weight surcharges, and current diesel fuel surcharges. In the event of destination re-routing, detention exceeding 30 minutes at loading docks, or incorrect weight declarations (>10% discrepancy), supplemental charges will apply.\n\nCancellation is permitted without penalty prior to driver dispatch. Post-dispatch cancellations incur a \$25.00 deadhead fee.',
                    ),
                    _buildSection(
                      number: '5.0',
                      title: 'Carrier Liability & Cargo Transit Insurance',
                      content:
                          'Under standard carriage terms, HAMHA liability for lost or damaged cargo is governed by the Carmack Amendment guidelines, capped at \$2.50 per pound (\$5.51 per kilogram) unless Supplemental Full-Value Cargo Insurance is declared and paid prior to dispatch. HAMHA shall not be held liable for acts of God, force majeure events, customs seizures, or latent defect in shipper packaging.',
                    ),
                    _buildSection(
                      number: '6.0',
                      title: 'Electronic Proof of Delivery (e-POD) & Invoices',
                      content:
                          'All delivery invoices generated by the system (INV-HMH-XXXXX) constitute authentic commercial receipts. Digital timestamps, recipient mobile signatures, and automated GPS waypoint confirmation at the drop-off coordinates constitute definitive Electronic Proof of Delivery (e-POD).',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Bottom Action Button
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: HamhaTheme.crispWhite,
                  border: Border(top: BorderSide(color: HamhaTheme.borderSubtle)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HamhaTheme.deepBlack,
                      foregroundColor: HamhaTheme.crispWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('I UNDERSTAND & AGREE'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection({required String number, required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                number,
                style: const TextStyle(
                  color: HamhaTheme.crimsonRed,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: HamhaTheme.deepBlack,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: HamhaTheme.textDark,
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

