import 'package:flutter/material.dart';

Map<int, Color> colorMap = {
  50: const Color(0xFF0A3042),
  100: const Color(0xFF0A3042),
  200: const Color(0x220A3042),
  300: const Color(0x4F0A3042),
  400: const Color(0x660A3042),
  500: const Color(0x880A3042),
  600: const Color(0x990A3042),
  700: const Color(0xAB0A3042),
  800: const Color(0xCC0A3042),
  900: const Color(0xFF0A3042),
};
Map<int, Color> colorSecondaryMap = {
  50: const Color(0xFF64ee85),
  100: const Color(0xFF64ee85),
  200: const Color(0x2264ee85),
  300: const Color(0x4F64ee85),
  400: const Color(0x6664ee85),
  500: const Color(0x8864ee85),
  600: const Color(0x9964ee85),
  700: const Color(0xAB64ee85),
  800: const Color(0xCC64ee85),
  900: const Color(0xFF64ee85),
};

int getColorLight(Color color) {
  return (color.red + color.green + color.blue);
}
