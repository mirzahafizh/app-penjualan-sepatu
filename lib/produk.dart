class Produk {
  final String id;
  final String nama;
  final double harga;
  final String deskripsi;

  Produk(
      {required this.id,
      required this.nama,
      required this.harga,
      required this.deskripsi});

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'],
      nama: json['nama'],
      harga: json['harga'],
      deskripsi: json['deskripsi'],
    );
  }
}
