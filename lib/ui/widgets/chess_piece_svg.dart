import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChessPieceSvg extends StatelessWidget {
  final String pieceType; // 'p', 'n', 'b', 'r', 'q', 'k'
  final bool isWhite;
  final double size;

  const ChessPieceSvg({
    super.key,
    required this.pieceType,
    required this.isWhite,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final key = '${isWhite ? 'w' : 'b'}${pieceType.toLowerCase()}';
    final svgString = _svgPieces[key];

    if (svgString == null) return const SizedBox.shrink();

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: SvgPicture.string(
          svgString,
          width: size * 0.94,
          height: size * 0.94,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  static const Map<String, String> _svgPieces = {
    // WHITE PAWN
    'wp': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <path d="m22.5 9c-2.21 0-4 1.79-4 4 0 .89.29 1.71.78 2.38C17.33 16.5 16 18.59 16 21c0 2.03.94 3.84 2.41 5.03-3 1.06-7.41 5.55-7.41 13.47h23c0-7.92-4.41-12.41-7.41-13.47 1.47-1.19 2.41-3 2.41-5.03 0-2.41-1.33-4.5-3.28-5.62.49-.67.78-1.49.78-2.38 0-2.21-1.79-4-4-4z" stroke="#000" stroke-width="1.5" stroke-linecap="round" fill="#fff"/>
</svg>''',

    // BLACK PAWN
    'bp': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <path d="m22.5 9c-2.21 0-4 1.79-4 4 0 .89.29 1.71.78 2.38C17.33 16.5 16 18.59 16 21c0 2.03.94 3.84 2.41 5.03-3 1.06-7.41 5.55-7.41 13.47h23c0-7.92-4.41-12.41-7.41-13.47 1.47-1.19 2.41-3 2.41-5.03 0-2.41-1.33-4.5-3.28-5.62.49-.67.78-1.49.78-2.38 0-2.21-1.79-4-4-4z" stroke="#000" stroke-width="1.5" stroke-linecap="round" fill="#2b2b2b"/>
</svg>''',

    // WHITE KNIGHT
    'wn': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18" fill="#fff"/>
    <path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 C 13.27,7.4 17.5,6.5 17.5,6.5 C 17.5,6.5 20.4,7.5 22,10 z" fill="#fff"/>
    <path d="M 9.5 25.5 A 0.5 0.5 0 1 1 8.5,25.5 A 0.5 0.5 0 1 1 9.5 25.5 z" fill="#000"/>
    <path d="M 15 15.5 A 0.5 1.5 0 1 1 14,15.5 A 0.5 1.5 0 1 1 15 15.5 z" fill="#000" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)"/>
  </g>
</svg>''',

    // BLACK KNIGHT
    'bn': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18" fill="#2b2b2b"/>
    <path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 C 13.27,7.4 17.5,6.5 17.5,6.5 C 17.5,6.5 20.4,7.5 22,10 z" fill="#2b2b2b"/>
    <path d="M 9.5 25.5 A 0.5 0.5 0 1 1 8.5,25.5 A 0.5 0.5 0 1 1 9.5 25.5 z" fill="#fff"/>
    <path d="M 15 15.5 A 0.5 1.5 0 1 1 14,15.5 A 0.5 1.5 0 1 1 15 15.5 z" fill="#fff" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)"/>
  </g>
</svg>''',

    // WHITE BISHOP
    'wb': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <g fill="#fff" stroke-linecap="butt">
      <path d="M 9,36 C 12.39,35.03 19.11,36.43 22.5,34 C 25.89,36.43 32.61,35.03 36,36 C 36,36 37.65,36.54 39,38 C 38.32,38.97 37.35,38.99 36,38.5 C 32.61,37.53 25.89,38.96 22.5,37.5 C 19.11,38.96 12.39,37.53 9,38.5 C 7.646,38.99 6.677,38.97 6,38 C 7.354,36.54 9,36 9,36 z"/>
      <path d="M 12,36 C 11,32 11,26 15,22 C 16.5,20.5 17.5,19 18.5,16 C 19.5,13 18.5,10 22.5,10 C 26.5,10 25.5,13 26.5,16 C 27.5,19 28.5,20.5 30,22 C 34,26 34,32 33,36 z"/>
      <path d="M 25 8 A 2.5 2.5 0 1 1 20,8 A 2.5 2.5 0 1 1 25 8 z"/>
    </g>
    <path d="M 17.5,26 L 27.5,26 M 15,30 L 30,30 M 22.5,15.5 L 22.5,20.5 M 20,18 L 25,18"/>
  </g>
</svg>''',

    // BLACK BISHOP
    'bb': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <g fill="#2b2b2b" stroke-linecap="butt">
      <path d="M 9,36 C 12.39,35.03 19.11,36.43 22.5,34 C 25.89,36.43 32.61,35.03 36,36 C 36,36 37.65,36.54 39,38 C 38.32,38.97 37.35,38.99 36,38.5 C 32.61,37.53 25.89,38.96 22.5,37.5 C 19.11,38.96 12.39,37.53 9,38.5 C 7.646,38.99 6.677,38.97 6,38 C 7.354,36.54 9,36 9,36 z"/>
      <path d="M 12,36 C 11,32 11,26 15,22 C 16.5,20.5 17.5,19 18.5,16 C 19.5,13 18.5,10 22.5,10 C 26.5,10 25.5,13 26.5,16 C 27.5,19 28.5,20.5 30,22 C 34,26 34,32 33,36 z"/>
      <path d="M 25 8 A 2.5 2.5 0 1 1 20,8 A 2.5 2.5 0 1 1 25 8 z"/>
    </g>
    <path d="M 17.5,26 L 27.5,26 M 15,30 L 30,30 M 22.5,15.5 L 22.5,20.5 M 20,18 L 25,18" stroke="#fff"/>
  </g>
</svg>''',

    // WHITE ROOK
    'wr': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#fff" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 9,39 L 36,39 L 36,36 L 9,36 z" stroke-linecap="butt"/>
    <path d="M 12,36 L 12,32 L 33,32 L 33,36 z" stroke-linecap="butt"/>
    <path d="M 11,14 L 11,9 L 15,9 L 15,11 L 20,11 L 20,9 L 25,9 L 25,11 L 30,11 L 30,9 L 34,9 L 34,14 z"/>
    <path d="M 34,14 L 31,17 L 14,17 L 11,14 z"/>
    <path d="M 14,17 L 14,29.5 L 31,29.5 L 31,17 z" stroke-linecap="butt" stroke-linejoin="miter"/>
    <path d="M 14,29.5 L 12,32 L 33,32 L 31,29.5 z"/>
  </g>
</svg>''',

    // BLACK ROOK
    'br': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#2b2b2b" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 9,39 L 36,39 L 36,36 L 9,36 z" stroke-linecap="butt"/>
    <path d="M 12,36 L 12,32 L 33,32 L 33,36 z" stroke-linecap="butt"/>
    <path d="M 11,14 L 11,9 L 15,9 L 15,11 L 20,11 L 20,9 L 25,9 L 25,11 L 30,11 L 30,9 L 34,9 L 34,14 z"/>
    <path d="M 34,14 L 31,17 L 14,17 L 11,14 z"/>
    <path d="M 14,17 L 14,29.5 L 31,29.5 L 31,17 z" stroke-linecap="butt" stroke-linejoin="miter"/>
    <path d="M 14,29.5 L 12,32 L 33,32 L 31,29.5 z"/>
  </g>
</svg>''',

    // WHITE QUEEN
    'wq': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#fff" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(-1,-1)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(15.5,-5.5)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(32,-1)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(7,-4.5)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(24,-4.5)"/>
    <path d="M 9,26 C 17.5,24.5 30,24.5 36,26 L 38.5,13.5 L 31,25 L 30.7,10.5 L 25.5,24.5 L 22.5,10 L 19.5,24.5 L 14.3,10.5 L 14,25 L 6.5,13.5 z"/>
    <path d="M 9,26 C 9,28 10.5,28 11.5,30 C 12.5,31.5 12.5,31 12,33.5 C 10.5,34.5 10.5,36 10.5,36 C 9,37.5 11,38.5 11,38.5 L 34,38.5 C 34,38.5 36,37.5 34.5,36 C 34.5,36 34.5,34.5 33,33.5 C 32.5,31 32.5,31.5 33.5,30 C 34.5,28 36,28 36,26 z"/>
    <path d="M 11.5,30 C 15,29 30,29 33.5,30" fill="none"/>
    <path d="M 12,33.5 C 18,32.5 27,32.5 33,33.5" fill="none"/>
  </g>
</svg>''',

    // BLACK QUEEN
    'bq': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="#2b2b2b" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(-1,-1)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(15.5,-5.5)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(32,-1)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(7,-4.5)"/>
    <path d="M 9 13 A 2 2 0 1 1 5,13 A 2 2 0 1 1 9 13 z" transform="translate(24,-4.5)"/>
    <path d="M 9,26 C 17.5,24.5 30,24.5 36,26 L 38.5,13.5 L 31,25 L 30.7,10.5 L 25.5,24.5 L 22.5,10 L 19.5,24.5 L 14.3,10.5 L 14,25 L 6.5,13.5 z"/>
    <path d="M 9,26 C 9,28 10.5,28 11.5,30 C 12.5,31.5 12.5,31 12,33.5 C 10.5,34.5 10.5,36 10.5,36 C 9,37.5 11,38.5 11,38.5 L 34,38.5 C 34,38.5 36,37.5 34.5,36 C 34.5,36 34.5,34.5 33,33.5 C 32.5,31 32.5,31.5 33.5,30 C 34.5,28 36,28 36,26 z"/>
    <path d="M 11.5,30 C 15,29 30,29 33.5,30" fill="none" stroke="#fff"/>
    <path d="M 12,33.5 C 18,32.5 27,32.5 33,33.5" fill="none" stroke="#fff"/>
  </g>
</svg>''',

    // WHITE KING
    'wk': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 22.5,11.63 L 22.5,6" stroke-linejoin="miter"/>
    <path d="M 20,8 L 25,8"/>
    <path d="M 22.5,25 C 22.5,25 27,17.5 25.5,14.5 C 24,11.5 21,11.5 19.5,14.5 C 18,17.5 22.5,25 22.5,25" fill="#fff" stroke-linecap="butt" stroke-linejoin="miter"/>
    <path d="M 11.5,37 C 17,40.5 28,40.5 33.5,37 C 33.5,34 31,31.5 31,28 C 31,24.5 27.5,22.5 27.5,22.5 C 27.5,22.5 25.5,24 22.5,24 C 19.5,24 17.5,22.5 17.5,22.5 C 17.5,22.5 14,24.5 14,28 C 14,31.5 11.5,34 11.5,37 z" fill="#fff"/>
    <path d="M 11.5,30 C 17,27 28,27 33.5,30"/>
    <path d="M 11.5,33.5 C 17,30.5 28,30.5 33.5,33.5"/>
    <path d="M 11.5,37 C 17,34 28,34 33.5,37"/>
  </g>
</svg>''',

    // BLACK KING
    'bk': '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 45 45">
  <g fill="none" fill-rule="evenodd" stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
    <path d="M 22.5,11.63 L 22.5,6" stroke-linejoin="miter"/>
    <path d="M 20,8 L 25,8"/>
    <path d="M 22.5,25 C 22.5,25 27,17.5 25.5,14.5 C 24,11.5 21,11.5 19.5,14.5 C 18,17.5 22.5,25 22.5,25" fill="#2b2b2b" stroke-linecap="butt" stroke-linejoin="miter"/>
    <path d="M 11.5,37 C 17,40.5 28,40.5 33.5,37 C 33.5,34 31,31.5 31,28 C 31,24.5 27.5,22.5 27.5,22.5 C 27.5,22.5 25.5,24 22.5,24 C 19.5,24 17.5,22.5 17.5,22.5 C 17.5,22.5 14,24.5 14,28 C 14,31.5 11.5,34 11.5,37 z" fill="#2b2b2b"/>
    <path d="M 11.5,30 C 17,27 28,27 33.5,30" stroke="#fff"/>
    <path d="M 11.5,33.5 C 17,30.5 28,30.5 33.5,33.5" stroke="#fff"/>
    <path d="M 11.5,37 C 17,34 28,34 33.5,37" stroke="#fff"/>
  </g>
</svg>''',
  };
}
