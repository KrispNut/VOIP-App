class LoginResponse {
  LoginResponse({required this.success, required this.data});

  final bool? success;
  final LoginData? data;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json["success"],
      data: json["data"] == null ? null : LoginData.fromJson(json["data"]),
    );
  }

  Map<String, dynamic> toJson() => {"success": success, "data": data?.toJson()};

  @override
  String toString() {
    return "$success, $data, ";
  }
}

class LoginData {
  LoginData({
    this.id,
    this.username,
    this.password,
    required this.serverIp,
    required this.extension,
    required this.extensionPassword,
    this.deviceType,
    this.token,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.v,
  });

  final String? id;
  final String? username;
  final String? password;
  final String serverIp;
  final String extension;
  final String extensionPassword;
  final String? deviceType;
  final String? token;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? v;

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      id: json["_id"],
      username: json["username"],
      password: json["password"],
      serverIp: json["serverIp"],
      extension: json["extension"],
      extensionPassword: json["extension_password"],
      deviceType: json["device_type"],
      token: json["token"],
      status: json["status"],
      createdAt: DateTime.tryParse(json["createdAt"] ?? ""),
      updatedAt: DateTime.tryParse(json["updatedAt"] ?? ""),
      v: json["__v"],
    );
  }

  Map<String, dynamic> toJson() => {
    "_id": id,
    "username": username,
    "password": password,
    "serverIp": serverIp,
    "extension": extension,
    "extension_password": extensionPassword,
    "device_type": deviceType,
    "token": token,
    "status": status,
    "createdAt": createdAt?.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
    "__v": v,
  };

  @override
  String toString() {
    return "$id, $username, $password, $serverIp, $extension, $extensionPassword, $deviceType, $token, $status, $createdAt, $updatedAt, $v, ";
  }
}
