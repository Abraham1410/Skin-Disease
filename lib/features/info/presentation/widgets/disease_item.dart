import 'package:flutter/material.dart';
import '../../data/models/disease_model.dart';

class DiseaseItem extends StatelessWidget {
  final Disease disease;
  final VoidCallback onTap;

  const DiseaseItem({
    super.key,
    required this.disease,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Image.asset(disease.image, width: 50),
        title: Text(disease.name),
        subtitle: Text(
          disease.symptom,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
