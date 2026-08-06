import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final image = img.Image(width: 64, height: 64);
  img.fill(image, color: img.ColorRgba8(0, 0, 0, 255)); // Black background
  
  img.drawString(image, "1.2G", font: img.arial24, color: img.ColorRgb8(255, 255, 255), x: 2, y: 20);
  
  final icoBytes = img.encodeIco(image);
  File('test_icon.ico').writeAsBytesSync(icoBytes);
  print('Done');
}
