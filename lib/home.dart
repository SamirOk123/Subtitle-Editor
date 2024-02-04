import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:subtitle_editor/subtitle_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<String> _resultTexts = [];

  void _splitText(String inputText) {
    _resultTexts = inputText.split(RegExp(r'\n\n|\r\n\r\n'));

    setState(() {});
  }

 Future<void> _pickSRTFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.any,
  );

  if (result != null && result.files.isNotEmpty) {
    File file = File(result.files.single.path!);

    // Check if the file has an SRT extension
    if (file.path.endsWith('.srt.txt')) {
      String content = await file.readAsString();
      _splitText(content);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubtitleEditor(texts: List.from(_resultTexts)),
        ),
      );
    } else {
     
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Invalid File Type'),
          content: Text('Please pick an SRT file.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Editor'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _pickSRTFile,
              child: const Text('Pick SRT File'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
