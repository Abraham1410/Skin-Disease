import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _loading = true;
  bool _saving = false;

  String _selected = 'en'; // default

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      final data = doc.data() ?? {};
      _selected = (data['language'] ?? 'en').toString();
    } catch (_) {
      _selected = 'en';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveLanguage(String value) async {
    setState(() {
      _selected = value;
      _saving = true;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('User not logged in');

      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'language': value,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Language saved: ${value.toUpperCase()}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryGreen = Color(0xFF1F4E20);
    const softBg = Color(0xFFF2F7F3);

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        backgroundColor: softBg,
        elevation: 0,
        title: Text(
          'Change Language',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: primaryGreen,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _tile(
                    title: 'English',
                    subtitle: 'EN',
                    value: 'en',
                    groupValue: _selected,
                    onChanged: _saving ? null : _saveLanguage,
                  ),
                  const SizedBox(height: 10),
                  _tile(
                    title: 'Bahasa Indonesia',
                    subtitle: 'ID',
                    value: 'id',
                    groupValue: _selected,
                    onChanged: _saving ? null : _saveLanguage,
                  ),
                  const SizedBox(height: 14),
                  if (_saving)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _tile({
    required String title,
    required String subtitle,
    required String value,
    required String groupValue,
    required void Function(String value)? onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onChanged == null ? null : () => onChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFE6F2E7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.language_outlined,
                color: const Color(0xFF1F4E20),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: onChanged == null ? null : (v) => onChanged(v!),
              activeColor: const Color(0xFF1F4E20),
            ),
          ],
        ),
      ),
    );
  }
}
