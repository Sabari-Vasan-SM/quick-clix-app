enum RetrieveKind { text, file }

class RetrieveResult {
  const RetrieveResult.text({required this.text})
    : kind = RetrieveKind.text,
      fileName = null,
      mimeType = null,
      size = null,
      downloadPath = null;

  const RetrieveResult.file({
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.downloadPath,
  }) : kind = RetrieveKind.file,
       text = null;

  final RetrieveKind kind;
  final String? text;
  final String? fileName;
  final String? mimeType;
  final int? size;
  final String? downloadPath;

  bool get isText => kind == RetrieveKind.text;

  bool get isFile => kind == RetrieveKind.file;

  factory RetrieveResult.fromJson(Map<String, dynamic> json) {
    final kind = json['kind']?.toString();
    if (kind == 'text') {
      return RetrieveResult.text(text: json['text']?.toString() ?? '');
    }
    if (kind == 'file') {
      return RetrieveResult.file(
        fileName: json['fileName']?.toString() ?? 'download.bin',
        mimeType: json['mimeType']?.toString() ?? 'application/octet-stream',
        size: (json['size'] as num?)?.toInt() ?? 0,
        downloadPath: json['downloadPath']?.toString() ?? '',
      );
    }
    throw const FormatException('Unknown response type.');
  }
}
