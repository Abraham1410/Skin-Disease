import 'package:flutter/material.dart';
import '../../data/models/virus_model.dart';

class VirusItem extends StatelessWidget {
  final Virus virus;
  final VoidCallback onTap;

  const VirusItem({
    super.key,
    required this.virus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: Image.asset(virus.image, width: 50),
        title: Text(virus.name),
        subtitle: Text(
          virus.type,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
