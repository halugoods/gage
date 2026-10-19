import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';

class DriverAccountScreen extends StatefulWidget {
  const DriverAccountScreen({super.key});

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
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                      child: const Text(
                        'S',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: GageTheme.primary),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Flexible(
                                child: Text(
                                  'Syamsul Maarif',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 18),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '+62 812-3456-7890',
                            style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'AD 4521 WN',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 2. Tiga Kartu Metrik Performa Mitra
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      'Rating Bintang',
                      '4.96 ★',
                      '520 Ulasan',
                      const Color(0xFFD97706),
                      const Color(0xFFFEF3C7),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Penerimaan',
                      '100%',
                      'Target > 80%',
                      GageTheme.accentGreen,
                      const Color(0xFFDCFCE7),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricCard(
                      'Penyelesaian',
                      '100%',
                      'Target > 85%',
                      const Color(0xFF2563EB),
                      const Color(0xFFDBEAFE),
                      isDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 3. Kendaraan Mitra
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
                      'Kendaraan Terdaftar',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, size: 28, color: GageTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Honda Vario 160cc (2023)',
                                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Plat AD 4521 WN • STNK Aktif s/d Okt 2028',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                    const Divider(height: 20),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('GageFood (Pesan Antar Makanan)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: _acceptFood,
                      activeThumbColor: GageTheme.primary,
                      onChanged: (v) => setState(() => _acceptFood = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('GageRide (Ojek Penumpang)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: _acceptRide,
                      activeThumbColor: GageTheme.primary,
                      onChanged: (v) => setState(() => _acceptRide = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('GageSend (Kirim Paket / Titip)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: _acceptSend,
                      activeThumbColor: GageTheme.primary,
                      onChanged: (v) => setState(() => _acceptSend = v),
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
                    ListTile(
                      leading: const Icon(Icons.help_outline_rounded, color: GageTheme.primary),
                      title: const Text('Pusat Bantuan & CS GAGE', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.shield_outlined, color: GageTheme.accentGreen),
                      title: const Text('SOP & Standar Keselamatan Mitra', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DriverBottomNavBar(currentIndex: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: Colors.grey),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
