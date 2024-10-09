class Produk {
  final int id;
  final String ukuran;
  final double rating; // Menyesuaikan dengan tipe data rating
  final String namaSepatu; // Mengganti nama menjadi sesuai dengan JSON
  final String image;
  final int harga; // Harga di JSON adalah integer
  final int diskon; // Diskon di JSON adalah integer
  final String deskripsi;

  Produk({
    required this.id,
    required this.ukuran,
    required this.rating,
    required this.namaSepatu,
    required this.image,
    required this.harga,
    required this.diskon,
    required this.deskripsi,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      id: json['id'], // ID adalah integer
      ukuran: json['ukuran'] ?? 'Unknown', // Default jika ukuran adalah null
      rating: json['rating']?.toDouble() ??
          0.0, // Menyediakan default jika rating adalah null
      namaSepatu:
          json['nama_sepatu'] ?? 'Unknown', // Ganti menjadi sesuai dengan JSON
      image: json['image'] ?? '', // Menyediakan default jika image adalah null
      harga: json['harga'], // Harga diambil langsung
      diskon: json['diskon'] ?? 0, // Default jika diskon adalah null
      deskripsi: json['deskripsi'] ??
          'No description available', // Default jika deskripsi adalah null
    );
  }
}
