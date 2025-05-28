import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SumadorDeCuentas(),
    );
  }
}

class SumadorDeCuentas extends StatefulWidget {
  const SumadorDeCuentas({super.key});
  @override
  State<SumadorDeCuentas> createState() => _SumadorDeCuentasState();
}

class _SumadorDeCuentasState extends State<SumadorDeCuentas> {
  final ImagePicker _picker = ImagePicker();
  double totalSum = 0;
  bool loading = false;

  Future<void> pickImagesAndSum() async {
    setState(() {
      loading = true;
      totalSum = 0;
    });

    double sum = 0;

    if (kIsWeb) {
      // En web solo una imagen (multi no soportado)
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) {
        setState(() {
          loading = false;
        });
        return;
      }
      sum = await _ocrSpaceApiSum(await image.readAsBytes());
    } else {
      // En móvil multi imagen con ML Kit
      final List<XFile>? images = await _picker.pickMultiImage();
      if (images == null || images.isEmpty) {
        setState(() {
          loading = false;
        });
        return;
      }

      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

      for (var image in images) {
        final inputImage = InputImage.fromFilePath(image.path);
        final recognizedText = await textRecognizer.processImage(inputImage);

        final regex = RegExp(r'(\d+[\.,]?\d*)\s*€');
        final matches = regex.allMatches(recognizedText.text);

        for (var match in matches) {
          String numberStr = match.group(1)!.replaceAll(',', '.');
          sum += double.tryParse(numberStr) ?? 0;
        }
      }
      await textRecognizer.close();
    }

    setState(() {
      totalSum = sum;
      loading = false;
    });
  }

  Future<double> _ocrSpaceApiSum(Uint8List imageBytes) async {
    const apiKey = 'helloworld'; // API KEY gratuita para pruebas
    final uri = Uri.parse('https://api.ocr.space/parse/image');

    final request = http.MultipartRequest('POST', uri);
    request.fields['apikey'] = apiKey;
    request.fields['language'] = 'eng';
    request.fields['isOverlayRequired'] = 'false';
    request.files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'image.jpg'));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    final Map<String, dynamic> jsonResponse = json.decode(respStr);
    if (jsonResponse['IsErroredOnProcessing'] == true) {
      return 0;
    }

    final parsedText = jsonResponse['ParsedResults'][0]['ParsedText'] as String;

    final regex = RegExp(r'(\d+[\.,]?\d*)\s*€');
    final matches = regex.allMatches(parsedText);

    double sum = 0;
    for (var match in matches) {
      String numberStr = match.group(1)!.replaceAll(',', '.');
      sum += double.tryParse(numberStr) ?? 0;
    }
    return sum;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sumador de cuentas')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : totalSum > 0
            ? Text(
          'Total: €${totalSum.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        )
            : const Text(
          'Selecciona imágenes para sumar las cuentas',
          style: TextStyle(fontSize: 20),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: pickImagesAndSum,
        tooltip: 'Seleccionar imágenes',
        child: const Icon(Icons.photo_library),
      ),
    );
  }
}
