import '../models/disease_model.dart';
import '../strings/app_strings.dart';

class DiseaseLocalData {
  static const List<Disease> diseases = [
    Disease(
      name: 'Cellulitis',
      reason: AppStrings.penyebabCellulitis,
      symptom: AppStrings.gejalaCellulitis,
      image: 'assets/images/cellulitis.jpg',
    ),
    Disease(
      name: 'Impetigo',
      reason: AppStrings.penyebabImpetigo,
      symptom: AppStrings.gejalaImpetigo,
      image: 'assets/images/impetigo.jpg',
    ),
    Disease(
      name: 'Athlete Foot',
      reason: AppStrings.penyebabAthleteFoot,
      symptom: AppStrings.gejalaAthleteFoot,
      image: 'assets/images/athlete_foot.jpg',
    ),
    Disease(
      name: 'Nail Fungus',
      reason: AppStrings.penyebabJamurKuku,
      symptom: AppStrings.gejalaJamurKuku,
      image: 'assets/images/nail_fungus.jpg',
    ),
    Disease(
      name: 'Ringworm',
      reason: AppStrings.penyebabKurap,
      symptom: AppStrings.gejalaKurap,
      image: 'assets/images/ringworm.jpg',
    ),
    Disease(
      name: 'Cutaneous Larva Migrans',
      reason: AppStrings.penyebabClm,
      symptom: AppStrings.gejalaClm,
      image: 'assets/images/clm.jpg',
    ),
    Disease(
      name: 'Chickenpox',
      reason: AppStrings.penyebabCacarAir,
      symptom: AppStrings.gejalaCacarAir,
      image: 'assets/images/chickenpox.jpg',
    ),
    Disease(
      name: 'Shingles',
      reason: AppStrings.penyebabHerpesZoster,
      symptom: AppStrings.gejalaHerpesZoster,
      image: 'assets/images/shingles.jpg',
    ),
  ];
}
