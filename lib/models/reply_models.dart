class Reply {
  final int id;
  final String name;
  final String message;
  final DateTime date;

  Reply({
    required this.id,
    required this.name,
    required this.message,
    required this.date,
  });

  // GANTI FACTORY LAMA ANDA DENGAN KODE FACTORY BARU DI BAWAH INI
  factory Reply.fromJson(Map<String, dynamic> json) {
    return Reply(
      // Parsing aman untuk ID
      id: json['id'] as int? ?? 0,

      // Parsing aman untuk nama dan pesan
      name: json['name']?.toString() ?? 'Unknown',
      message: json['message']?.toString() ?? '',

      // PERBAIKAN: Menggunakan kunci 'reply_date' dan metode tryParse yang aman
      date:
          DateTime.tryParse(json['reply_date']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
