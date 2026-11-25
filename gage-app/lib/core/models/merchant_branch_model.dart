/// Data model representing a physical merchant outlet / branch under one partner account.
class MerchantBranch {
  final String id;
  final String name;
  final String address;
  final String landmark;
  final String phone;
  final bool isPrimary;
  final bool isOpen;
  final double latitude;
  final double longitude;

  const MerchantBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.landmark,
    required this.phone,
    this.isPrimary = false,
    this.isOpen = true,
    this.latitude = -8.0892,
    this.longitude = 110.8374,
  });

  MerchantBranch copyWith({
    String? id,
    String? name,
    String? address,
    String? landmark,
    String? phone,
    bool? isPrimary,
    bool? isOpen,
    double? latitude,
    double? longitude,
  }) {
    return MerchantBranch(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      landmark: landmark ?? this.landmark,
      phone: phone ?? this.phone,
      isPrimary: isPrimary ?? this.isPrimary,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'landmark': landmark,
        'phone': phone,
        'isPrimary': isPrimary,
        'isOpen': isOpen,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory MerchantBranch.fromJson(Map<String, dynamic> json) {
    return MerchantBranch(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      address: (json['address'] ?? '').toString(),
      landmark: (json['landmark'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      isPrimary: json['isPrimary'] == true,
      isOpen: json['isOpen'] != false,
      latitude: (json['latitude'] as num?)?.toDouble() ?? -8.0892,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 110.8374,
    );
  }
}
