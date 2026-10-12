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
      } else {
        // Fallback default dev customer session agar saat install ulang langsung masuk Beranda tanpa tertahan login
        _currentUser = UserModel(
          id: 'usr-cust-01',
          name: 'Syams Djuhair Hibatullah',
          email: 'halugoods.indonesia@gmail.com',
          phone: '085156955735',
          role: 'customer',
        );
        await prefs.setString('gage_user_session', jsonEncode(_currentUser!.toJson()));
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
        // Fallback jika idToken null di platform tertentu, gunakan dev login dengan info profil Google
        return await signInDev(
          email: googleUser.email,
          name: googleUser.displayName ?? 'Pengguna Gage',
          userId: 'usr-g-${googleUser.id.substring(0, 10)}',
        );
      }

      // Kirim ID Token ke Cloudflare Worker untuk validasi & D1 sync
      final res = await GageApiClient.loginWithGoogle(idToken);
      if (res != null && res['success'] == true) {
        final userData = res['data']['user'];
        final token = res['token'];
        _currentUser = UserModel.fromJson(userData, token: token);
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
        final token = res['token'];
        _currentUser = UserModel.fromJson(userData, token: token);
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

  // Perbarui Profil Pengguna (Nama, No WhatsApp, Email, & Avatar)
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return false;
    try {
      await GageApiClient.updateUserProfile(_currentUser!.id, name: name, phone: phone);
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
    _currentUser = null;
    notifyListeners();
  }
}
