class UploadReceipt {
  const UploadReceipt({required this.pin, this.expiresAt});

  final String pin;
  final DateTime? expiresAt;

  factory UploadReceipt.fromJson(Map<String, dynamic> json) {
    final expiresAtMs = json['expiresAt'];
    return UploadReceipt(
      pin: json['pin']?.toString() ?? '',
      expiresAt: expiresAtMs is int
          ? DateTime.fromMillisecondsSinceEpoch(expiresAtMs)
          : null,
    );
  }
}
