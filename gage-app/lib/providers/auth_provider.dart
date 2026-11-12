import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthProvider() {
    loadSavedSession();
  }

  // Muat sesi tersimpan dari SharedPreferences saat aplikasi pertama dibuka
  Future<void> loadSavedSession() async {
    _isLoading = true;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('gage_user_session');
      if (userJson != null) {
        final Map<String, dynamic> data = jsonDecode(userJson);
        _currentUser = UserModel.fromJson(data);
        final savedAvatar = prefs.getString('gage_user_avatar');
        if (savedAvatar != null && savedAvatar.isNotEmpty) {
          _currentUser = _currentUser!.copyWith(avatarUrl: savedAvatar);
        }
        GageApiClient.authToken = _currentUser?.token;
      } else if (GageApiClient.useDevSeedData) {
        // Fallback default dev customer session hanya saat mode dev-seed aktif
        final savedAvatar = prefs.getString('gage_user_avatar');
        _currentUser = UserModel(
          id: 'usr-cust-01',
          name: 'Syams Djuhair Hibatullah',
          email: 'halugoods.indonesia@gmail.com',
          phone: '085156955735',
          role: 'customer',
          avatarUrl: savedAvatar,
        );
        await prefs.setString('gage_user_session', jsonEncode(_currentUser!.toJson()));
      } else {
        GageApiClient.authToken = null;
      }
    } catch (e) {
      debugPrint('Error loading saved session: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Simpan sesi ke SharedPreferences
  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gage_user_session', jsonEncode(user.toJson()));
  }

  // Official Standalone Google Sign-In (Tanpa Firebase!)
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Pengguna membatalkan dialog login Google
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        if (GageApiClient.useDevSeedData) {
          return await signInDev(
            email: googleUser.email,
            name: googleUser.displayName ?? 'Pengguna Gage',
            userId: 'usr-g-${googleUser.id.substring(0, 10)}',
          );
        }
        _errorMessage = 'Token autentikasi Google tidak tersedia';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Kirim ID Token ke Cloudflare Worker untuk validasi & D1 sync
      final res = await GageApiClient.loginWithGoogle(idToken);
      if (res != null && res['success'] == true) {
        final userData = res['data']['user'];
        final token = res['token']?.toString();
        _currentUser = UserModel.fromJson(userData, token: token);
        GageApiClient.authToken = token;
        await _saveSession(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message'] ?? 'Verifikasi Google gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kendala saat login Google: $e';
      // Fallback ke dev login jika Google Play Services tidak tersedia di emulator
      debugPrint('Google Sign-In fallback: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Dev Fast Login Bypass (Sangat cepat untuk testing di HP)
  Future<bool> signInDev({
    String userId = 'usr-cust-01',
    String name = 'Pelanggan Setia Gage',
    String email = 'test-customer@gage.id',
    String phone = '081234567893',
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await GageApiClient.loginDev(
        userId: userId,
        name: name,
        email: email,
        phone: phone,
      );

      if (res != null && res['success'] == true) {
        final userData = res['data']['user'];
        final token = res['token']?.toString();
        _currentUser = UserModel.fromJson(userData, token: token);
        GageApiClient.authToken = token;
        await _saveSession(_currentUser!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res?['message'] ?? 'Login Dev gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Gagal login dev: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Masuk / Daftar dengan Nomor WhatsApp (OTP Ready)
  Future<bool> signInWithPhone({
    required String phone,
    String? name,
    String? referralCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanDigits.startsWith('0')
          ? cleanDigits
          : (cleanDigits.startsWith('62') ? '0${cleanDigits.substring(2)}' : '0$cleanDigits');
      final userId = 'usr-wa-${formattedPhone.length > 4 ? formattedPhone.substring(formattedPhone.length - 6) : formattedPhone}';
      final displayName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Pengguna GAGE';

      _currentUser = UserModel(
        id: userId,
        name: displayName,
        phone: formattedPhone,
        email: '$formattedPhone@gage.id',
        role: 'customer',
      );
      await _saveSession(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Gagal masuk dengan nomor WhatsApp: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Perbarui Profil Pengguna (Nama, No WhatsApp, Email, & Avatar)
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    try {
      await GageApiClient.updateUserProfile(
        _currentUser!.id,
        name: name,
        phone: phone,
        email: email,
        avatarUrl: avatarUrl,
      );
    } catch (e) {
      debugPrint('Cloud profile sync notice: $e');
    }
    _currentUser = _currentUser!.copyWith(
      name: name,
      phone: phone,
      email: email,
      avatarUrl: avatarUrl,
    );
    await _saveSession(_currentUser!);
    notifyListeners();
    return true;
  }

  // Logout & Bersihkan Sesi
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('gage_user_session');
    GageApiClient.authToken = null;
    _currentUser = null;
    notifyListeners();
  }
}
