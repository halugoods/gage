import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';

class DriverAccountScreen extends StatefulWidget {
  final bool showBottomNav;
  const DriverAccountScreen({super.key, this.showBottomNav = false});

  @override
  State<DriverAccountScreen> createState() => _DriverAccountScreenState();
}

class _DriverAccountScreenState extends State<DriverAccountScreen> {
  double _maxDistance = 5.0;
  bool _acceptRide = true;
  bool _acceptFood = true;
  bool _acceptSend = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        title: const Text(
          'Profil & Akun Mitra',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Profil Mitra Driver
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                          child: const Text(
                            'S',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: GageTheme.primary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'Syamsul Maarif',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.verified_rounded, size: 16, color: Color(0xFF1E88E5)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mitra Kurir Motor • GAGE Pracimantoro',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.star_rounded, size: 13, color: Color(0xFFD97706)),
                                    SizedBox(width: 3),
                                    Text('4.96', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFB45309))),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AD 5821 QG',
                                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Metrik Performa Kerja
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Penerimaan',
                      '100%',
                      'Target min 80%',
                      GageTheme.accentGreen,
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Penyelesaian',
                      '98.5%',
                      'Bagus sekali',
                      const Color(0xFF1E88E5),
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildMetricCard(
                      'Rating',
                      '4.96',
                      '500+ Trip',
                      const Color(0xFFD97706),
                      isDark ? const Color(0xFF1E293B) : Colors.white,
                      isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Kendaraan & Dokumen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Kendaraan & Legalitas',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Jenis Kendaraan', 'Sepeda Motor (Honda Vario 125)', isDark),
                    const Divider(height: 16),
                    _buildInfoRow('Plat Nomor', 'AD 5821 QG', isDark),
                    const Divider(height: 16),
                    _buildInfoRow('Masa Berlaku SIM C', 'Aktif s/d 2028', isDark),
                    const Divider(height: 16),
                    _buildInfoRow('Status STNK', 'Terverifikasi Tim Pusat', isDark),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Preferensi Kerja & Radius
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preferensi Layanan & Radius',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Radius Jemput Maksimal', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(
                          '${_maxDistance.toStringAsFixed(1)} KM',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: GageTheme.primary),
                        ),
                      ],
                    ),
                    Slider(
                      value: _maxDistance,
                      min: 1.0,
                      max: 15.0,
                      divisions: 14,
                      activeColor: GageTheme.primary,
                      onChanged: (val) {
                        setState(() => _maxDistance = val);
                      },
                    ),
                    const Divider(height: 16),

                    // Toggle Food
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GAGE Food (Pesan Antar Makanan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _acceptFood,
                          activeThumbColor: GageTheme.primary,
                          onChanged: (v) => setState(() => _acceptFood = v),
                        ),
                      ],
                    ),
                    const Divider(height: 12),

                    // Toggle Ride
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GAGE Ride (Ojek Penumpang)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _acceptRide,
                          activeThumbColor: GageTheme.primary,
                          onChanged: (v) => setState(() => _acceptRide = v),
                        ),
                      ],
                    ),
                    const Divider(height: 12),

                    // Toggle Send
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('GAGE Send (Kirim Paket / Titip)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _acceptSend,
                          activeThumbColor: GageTheme.primary,
                          onChanged: (v) => setState(() => _acceptSend = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. SOP & Pusat Bantuan
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.help_outline_rounded, color: GageTheme.primary, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('Pusat Bantuan & CS GAGE', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Icon(Icons.shield_outlined, color: GageTheme.accentGreen, size: 20),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text('SOP & Standar Keselamatan Mitra', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.showBottomNav ? const DriverBottomNavBar(currentIndex: 4) : null,
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String subtitle,
    Color color,
    Color bg,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
