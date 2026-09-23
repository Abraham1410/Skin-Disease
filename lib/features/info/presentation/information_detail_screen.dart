import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/information_data.dart';

class InformationDetailScreen extends StatelessWidget {
  final InfoArticle article;

  const InformationDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          article.title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryGreen,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(article.imageUrl),
            ),
            const SizedBox(height: 16),
            Text(
              article.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article.description * 5, // dummy, nanti bisa diganti full content
              style: GoogleFonts.poppins(
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
