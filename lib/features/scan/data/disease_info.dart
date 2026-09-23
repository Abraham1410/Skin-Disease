class DiseaseInfo {
  final String displayName;
  final String description;
  final List<String> prevention;

  const DiseaseInfo({
    required this.displayName,
    required this.description,
    required this.prevention,
  });
}

const Map<String, DiseaseInfo> diseaseInfoMap = {
  'BA- cellulitis': DiseaseInfo(
    displayName: 'Cellulitis',
    description:
        'Cellulitis adalah infeksi bakteri pada lapisan kulit yang lebih dalam. Gejalanya dapat berupa kemerahan, bengkak, nyeri, dan kulit terasa hangat.',
    prevention: [
      'Jaga kebersihan kulit dan luka.',
      'Bersihkan luka, gigitan, atau goresan dengan baik.',
      'Hindari menggaruk area kulit yang terluka.',
      'Segera periksa ke tenaga kesehatan jika kemerahan cepat meluas, nyeri berat, atau disertai demam.',
    ],
  ),

  'BA-impetigo': DiseaseInfo(
    displayName: 'Impetigo',
    description:
        'Impetigo adalah infeksi kulit menular yang sering menimbulkan luka atau keropeng kekuningan pada kulit.',
    prevention: [
      'Cuci tangan secara rutin.',
      'Jangan berbagi handuk, pakaian, atau linen dengan penderita.',
      'Cuci pakaian, handuk, dan seprai setiap hari bila ada infeksi.',
      'Potong kuku agar tidak mudah melukai kulit saat menggaruk.',
    ],
  ),

  'FU-athlete-foot': DiseaseInfo(
    displayName: 'Athlete’s Foot / Kutu Air',
    description:
        'Athlete’s foot atau kutu air adalah infeksi jamur yang umumnya menyerang sela-sela jari kaki dan dapat menyebabkan gatal, kulit mengelupas, atau perih.',
    prevention: [
      'Jaga kaki tetap bersih dan kering.',
      'Ganti kaus kaki secara rutin.',
      'Gunakan sandal di area lembap seperti kamar mandi umum.',
      'Hindari memakai sepatu yang terlalu lembap dalam waktu lama.',
    ],
  ),

  'FU-nail-fungus': DiseaseInfo(
    displayName: 'Nail Fungus / Jamur Kuku',
    description:
        'Jamur kuku adalah infeksi jamur pada kuku yang dapat menyebabkan kuku berubah warna, menebal, rapuh, atau mudah rusak.',
    prevention: [
      'Jaga kuku tetap pendek, bersih, dan kering.',
      'Hindari berbagi alat pemotong kuku.',
      'Gunakan alas kaki di tempat umum yang lembap.',
      'Segera tangani infeksi jamur pada kaki agar tidak menyebar ke kuku.',
    ],
  ),

  'FU-ringworm': DiseaseInfo(
    displayName: 'Ringworm / Kurap',
    description:
        'Ringworm atau kurap adalah infeksi jamur pada kulit yang sering berbentuk ruam melingkar, kemerahan, bersisik, dan terasa gatal.',
    prevention: [
      'Jaga kulit tetap bersih dan kering.',
      'Hindari berbagi handuk, pakaian, atau alat pribadi.',
      'Cuci pakaian dan handuk setelah digunakan.',
      'Hindari kontak langsung dengan area kulit yang terinfeksi.',
    ],
  ),

  'PA-cutaneous-larva-migrans': DiseaseInfo(
    displayName: 'Cutaneous Larva Migrans',
    description:
        'Cutaneous larva migrans adalah kondisi kulit akibat larva parasit yang masuk ke kulit, biasanya menimbulkan garis atau pola berkelok yang terasa gatal.',
    prevention: [
      'Gunakan alas kaki saat berjalan di tanah atau pasir.',
      'Hindari kontak langsung kulit dengan tanah atau pasir yang berisiko terkontaminasi.',
      'Gunakan alas duduk saat berada di pantai atau tanah terbuka.',
      'Jaga kebersihan lingkungan dari kotoran hewan.',
    ],
  ),

  'VI-chickenpox': DiseaseInfo(
    displayName: 'Chickenpox / Cacar Air',
    description:
        'Chickenpox atau cacar air adalah penyakit menular akibat virus varicella-zoster yang dapat menyebabkan ruam berisi cairan dan rasa gatal.',
    prevention: [
      'Vaksinasi varicella sesuai anjuran tenaga kesehatan.',
      'Hindari kontak dekat dengan penderita cacar air.',
      'Jaga kebersihan tangan.',
      'Istirahat di rumah saat sedang menular untuk mencegah penyebaran.',
    ],
  ),

  'VI-shingles': DiseaseInfo(
    displayName: 'Shingles / Herpes Zoster',
    description:
        'Shingles atau herpes zoster adalah ruam kulit nyeri akibat reaktivasi virus varicella-zoster, virus yang sama dengan penyebab cacar air.',
    prevention: [
      'Konsultasikan vaksin herpes zoster bila termasuk kelompok yang dianjurkan.',
      'Jaga daya tahan tubuh.',
      'Hindari kontak langsung dengan cairan lepuhan pada ruam.',
      'Tutup area ruam agar tidak mudah menular ke orang yang rentan.',
    ],
  ),
};