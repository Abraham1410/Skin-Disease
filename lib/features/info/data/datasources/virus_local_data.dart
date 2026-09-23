import '../models/virus_model.dart';
import '../strings/app_strings.dart';

class VirusLocalData {
  static const List<Virus> viruses = [
    Virus(
      name: 'BA - BAKTERI',
      explanation: AppStrings.penjelasanBABakteri,
      type: AppStrings.jenisInfeksiBABakteri,
      image: 'assets/images/bakteri.jpg',
    ),
    Virus(
      name: 'FU - FUNGUS',
      explanation: AppStrings.penjelasanFUFungus,
      type: AppStrings.jenisInfeksiFUFungus,
      image: 'assets/images/jamur.jpg',
    ),
    Virus(
      name: 'PA - PARASIT',
      explanation: AppStrings.penjelasanPAParasit,
      type: AppStrings.jenisInfeksiPAParasit,
      image: 'assets/images/parasit.jpg',
    ),
    Virus(
      name: 'VI - VIRUS',
      explanation: AppStrings.penjelasanVIVirus,
      type: AppStrings.jenisInfeksiVIVirus,
      image: 'assets/images/virus.jpg',
    ),
  ];
}
