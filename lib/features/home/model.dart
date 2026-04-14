class CallResponse {
  CallResponse({
    required this.success,
    required this.message,
    required this.apnsResponse,
  });

  final bool? success;
  final String? message;
  final ApnsResponse? apnsResponse;

  factory CallResponse.fromJson(Map<String, dynamic> json) {
    return CallResponse(
      success: json["success"],
      message: json["message"],
      apnsResponse: json["apns_response"] == null
          ? null
          : ApnsResponse.fromJson(json["apns_response"]),
    );
  }

  Map<String, dynamic> toJson() => {
    "success": success,
    "message": message,
    "apns_response": apnsResponse?.toJson(),
  };

  @override
  String toString() {
    return "$success, $message, $apnsResponse, ";
  }
}

class ApnsResponse {
  ApnsResponse({required this.sent, required this.failed});

  final List<Sent> sent;
  final List<dynamic> failed;

  factory ApnsResponse.fromJson(Map<String, dynamic> json) {
    return ApnsResponse(
      sent: json["sent"] == null
          ? []
          : List<Sent>.from(json["sent"]!.map((x) => Sent.fromJson(x))),
      failed: json["failed"] == null
          ? []
          : List<dynamic>.from(json["failed"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
    "sent": sent.map((x) => x.toJson()).toList(),
    "failed": failed.map((x) => x).toList(),
  };

  @override
  String toString() {
    return "$sent, $failed, ";
  }
}

class Sent {
  Sent({required this.device});

  final String? device;

  factory Sent.fromJson(Map<String, dynamic> json) {
    return Sent(device: json["device"]);
  }

  Map<String, dynamic> toJson() => {"device": device};

  @override
  String toString() {
    return "$device, ";
  }
}
