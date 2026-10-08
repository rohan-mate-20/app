class CustomerModel {
  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? authUserId;
  final String? dob;
  final bool whatsappOptIn;
  final bool isVerified;
  final String avatar;

  CustomerModel({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.authUserId,
    this.dob,
    this.whatsappOptIn = true,
    this.isVerified = true,
    this.avatar = '',
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] ?? '',
      phone: json['phone'] ?? '',
      name: json['name'],
      email: json['email'],
      authUserId: json['auth_user_id'],
      dob: json['dob'],
      whatsappOptIn: json['whatsapp_opt_in'] ?? true,
      isVerified: true,
      avatar: json['avatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'email': email,
      'auth_user_id': authUserId,
    };
  }

  CustomerModel copyWith({
    String? id,
    String? phone,
    String? name,
    String? email,
    String? authUserId,
    String? dob,
    bool? whatsappOptIn,
    bool? isVerified,
    String? avatar,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      email: email ?? this.email,
      authUserId: authUserId ?? this.authUserId,
      dob: dob ?? this.dob,
      whatsappOptIn: whatsappOptIn ?? this.whatsappOptIn,
      isVerified: isVerified ?? this.isVerified,
      avatar: avatar ?? this.avatar,
    );
  }
}