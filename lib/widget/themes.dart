import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyTheme {
  static ThemeData lightTheme(BuildContext context) => ThemeData(
        primaryColor: Color(0xFF69BF6F),
        fontFamily: GoogleFonts.lato().fontFamily,
        appBarTheme: const AppBarTheme(
          color: Colors.white,
          elevation: 0.0,
          iconTheme: IconThemeData(color: Colors.black),
          foregroundColor: Colors.black,
        ),
      );

  static ThemeData darkTheme(BuildContext context) => ThemeData(
        brightness: Brightness.dark,
      );
}
