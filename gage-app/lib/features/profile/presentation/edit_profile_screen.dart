import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;

  File? _imageFile;
  String? _selectedPreset;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Preset avatar lokal
  final List<Map<String, String>> _presetAvatars = [
    {
      'name': 'GAGE Klasik',
      'path': 'assets/images/avatar_user.png',
      'desc': 'Avatar default resmi',
    },
    {
      'name': 'Pelanggan Juara',
      'path': 'assets/images/nav_profile_active.png',
      'desc': 'Ikon hijau ramah',
    },
    {
      'name': 'Mitra Prioritas',
      'path': 'assets/icons/ic_ride.png',
      'desc': 'Karakter mobilitas',
    },
    {
      'name': 'Food Explorer',
      'path': 'assets/icons/ic_food.png',
      'desc': 'Penikmat kuliner',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;

    _nameController = TextEditingController(
      text: user?.name.isNotEmpty == true ? user!.name : 'Syams Djuhair Hibatullah',
    );
    _phoneController = TextEditingController(
      text: user?.phone.isNotEmpty == true ? user!.phone : '+6285156955735',
    );
    _emailController = TextEditingController(
      text: user?.email?.isNotEmpty == true ? user!.email : 'halugoods.indonesia@gmail.com',
    );
    _addressController = TextEditingController(
      text: 'Dusun Tubokarto RT 02/RW 01, Tubokarto, Pracimantoro, Kab. Wonogiri',
    );

    _loadPrimaryAddress();
  }

  Future<void> _loadPrimaryAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedAddress = prefs.getString('gage_primary_address');
      if (savedAddress != null && savedAddress.isNotEmpty) {
        setState(() {
          _addressController.text = savedAddress;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Ambil gambar dari Kamera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
          _selectedPreset = null;
        });
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(
          context,
          'Gagal mengakses kamera: $e',
          type: GageToastType.error,
        );
      }
    }
  }

  // Ambil gambar dari Galeri
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _selectedPreset = null;
        });
      }
    } catch (e) {
      if (mounted) {
        GageToast.show(
          context,
          'Gagal memilih foto dari galeri: $e',
          type: GageToastType.error,
        );
      }
    }
  }

  // Pilih dari Preset Avatar
  void _showPresetAvatarPicker() {
    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.face_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pilih Preset Avatar',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Gunakan karakter resmi GAGE Pracimantoro untuk profil Anda',
            style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: _presetAvatars.length,
            itemBuilder: (c, idx) {
              final preset = _presetAvatars[idx];
              final isSelected = _selectedPreset == preset['path'];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPreset = preset['path'];
                    _imageFile = null;
                  });
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFFFEBEE) : const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? GageTheme.primary : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage(preset['path']!),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preset['name']!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? GageTheme.primary : GageTheme.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Modal Sheet Opsi Ganti Avatar
  void _showAvatarOptionsSheet() {
    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Ubah Foto Profil',
                  style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: GageTheme.primary, size: 22),
            ),
            title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Gunakan kamera langsung untuk potret diri', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromCamera();
            },
          ),
          const Divider(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.photo_library_rounded, color: Color(0xFF1976D2), size: 22),
            ),
            title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Pilih foto tersimpan dari memori ponsel', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _pickImageFromGallery();
            },
          ),
          const Divider(height: 8),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.face_rounded, color: Color(0xFFE65100), size: 22),
            ),
            title: const Text('Pilih dari Preset Avatar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Pilihan avatar_user.png dan karakter GAGE', style: TextStyle(fontSize: 12)),
            onTap: () {
              Navigator.pop(context);
              _showPresetAvatarPicker();
            },
          ),
        ],
      ),
    );
  }

  // Simpan Perubahan Profil
  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();
    final newEmail = _emailController.text.trim();
    final newAddress = _addressController.text.trim();

    String? newAvatarUrl;
    if (_imageFile != null) {
      newAvatarUrl = _imageFile!.path;
    } else if (_selectedPreset != null) {
      newAvatarUrl = _selectedPreset;
    } else {
      newAvatarUrl = auth.currentUser?.avatarUrl;
    }

    try {
      // 1. Simpan Alamat Utama ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gage_primary_address', newAddress);
      if (newAvatarUrl != null) {
        await prefs.setString('gage_user_avatar', newAvatarUrl);
      }

      // 2. Update Profil di AuthProvider
      await auth.updateProfile(
        name: newName,
        phone: newPhone,
        email: newEmail,
        avatarUrl: newAvatarUrl,
      );

      if (!mounted) return;

      GageToast.show(
        context,
        'Profil berhasil diperbarui!',
        type: GageToastType.success,
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        GageToast.show(
          context,
          'Terjadi kesalahan: $e',
          type: GageToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Ubah Profil',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: GageTheme.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: GageTheme.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // 1. Avatar Interaktif dengan Badge Ikon Kamera
              Center(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: _showAvatarOptionsSheet,
                      borderRadius: BorderRadius.circular(60),
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: GageTheme.primary, width: 3),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildAvatarImage(user?.avatarUrl),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showAvatarOptionsSheet,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _showAvatarOptionsSheet,
                icon: const Icon(Icons.edit_rounded, size: 16, color: GageTheme.primary),
                label: const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: GageTheme.primary,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 2. Form Input Interaktif Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Lengkap
                    _buildInputField(
                      controller: _nameController,
                      label: 'Nama Lengkap',
                      hint: 'Masukkan nama lengkap Anda',
                      icon: Icons.person_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Nomor WhatsApp
                    _buildInputField(
                      controller: _phoneController,
                      label: 'Nomor WhatsApp',
                      hint: 'Contoh: +628123456789',
                      icon: Icons.phone_android_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor WhatsApp tidak boleh kosong';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Alamat Email
                    _buildInputField(
                      controller: _emailController,
                      label: 'Alamat Email',
                      hint: 'nama@domain.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Alamat email tidak boleh kosong';
                        }
                        if (!val.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Alamat Pengantaran Utama
                    _buildInputField(
                      controller: _addressController,
                      label: 'Alamat Pengantaran Utama',
                      hint: 'Nama jalan, dusun, RT/RW, dan patokan rumah',
                      icon: Icons.location_on_outlined,
                      maxLines: 3,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Alamat pengantaran utama wajib diisi';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 3. Tombol Simpan Perubahan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _handleSave,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(String? currentUrl) {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    if (_selectedPreset != null) {
      return Image.asset(_selectedPreset!, fit: BoxFit.cover);
    }
    if (currentUrl != null && currentUrl.isNotEmpty) {
      if (currentUrl.startsWith('assets/')) {
        return Image.asset(currentUrl, fit: BoxFit.cover);
      }
      if (currentUrl.startsWith('/') || currentUrl.contains('\\')) {
        final f = File(currentUrl);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover);
        }
      }
      return Image.network(
        currentUrl,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/avatar_user.png', fit: BoxFit.cover);
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: GageTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: Icon(icon, color: GageTheme.primary, size: 20),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
