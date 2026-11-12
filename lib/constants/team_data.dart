class TeamMember {
  final String name;
  final String studentId;
  final String role;
  final String university;
  final String imagePath;
  final String quote;

  const TeamMember({
    required this.name,
    required this.studentId,
    required this.role,
    required this.university,
    required this.imagePath,
    required this.quote,
  });
}

class TeamData {
  static const String capstoneId = 'CC26-PSU246';
  static const String programName = 'Coding Camp 2026';
  static const String supporter = 'DBS Foundation';
  static const String streamlitUrl = 'https://pilahnusaaidashboard.streamlit.app/';
  static const String githubUrl = 'https://github.com/milen06/PilahNusa-AI';

  static const List<TeamMember> members = [
    TeamMember(
      name: 'Irdan Guntara',
      studentId: 'CACC246D6Y0874',
      role: 'Project Manager & AI Engineer',
      university: 'Universitas Kuningan',
      imagePath: 'assets/images/teams/irdan.jpg',
      quote: 'Memadukan kecerdasan buatan dengan kepedulian lingkungan untuk masa depan bumi yang bersih.',
    ),
    TeamMember(
      name: 'Galih Rizaldy',
      studentId: 'CACC246D6Y0535',
      role: 'AI Engineer',
      university: 'Universitas Kuningan',
      imagePath: 'assets/images/teams/galih.jpg',
      quote: 'Mengembangkan model Machine Learning yang akurat dan responsif demi kemudahan memilah sampah.',
    ),
    TeamMember(
      name: 'Ema Maleni',
      studentId: 'CFCC174D6X0683',
      role: 'Full-Stack Web & Mobile Developer',
      university: 'Universitas Primakara',
      imagePath: 'assets/images/teams/ema.jpeg',
      quote: 'Menghadirkan pengalaman aplikasi yang ramah pengguna, intuitif, dan berdampak nyata bagi masyarakat.',
    ),
    TeamMember(
      name: 'Nayarah Atmawardani',
      studentId: 'CFCC362D6X1422',
      role: 'Full-Stack Web & Mobile Developer',
      university: 'Universitas Sulawesi Barat',
      imagePath: 'assets/images/teams/naya.jpg',
      quote: 'Membangun antarmuka modern yang menghubungkan edukasi lingkungan dengan interaksi visual.',
    ),
    TeamMember(
      name: 'Ryan Dwi Antoni',
      studentId: 'CDCC284D6Y1670',
      role: 'Data Scientist',
      university: 'Universitas Negeri Surabaya',
      imagePath: 'assets/images/teams/ryan.jpg',
      quote: 'Meneliti dan menganalisis dataset sampah Indonesia agar model AI mampu memprediksi secara akurat.',
    ),
    TeamMember(
      name: 'Gisca Oktavia Ramadhani',
      studentId: 'CDCC246D6X2496',
      role: 'Data Scientist',
      university: 'Universitas Kuningan',
      imagePath: 'assets/images/teams/gisca.png',
      quote: 'Menyajikan wawasan data pengelolaan sampah melalui dashboard interaktif untuk edukasi publik.',
    ),
  ];
}

