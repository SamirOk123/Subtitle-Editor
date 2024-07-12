import 'dart:io';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:file_picker/file_picker.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VideoSubtitlePlayer(),
    );
  }
}

class VideoSubtitlePlayer extends StatefulWidget {
  @override
  _VideoSubtitlePlayerState createState() => _VideoSubtitlePlayerState();
}

class _VideoSubtitlePlayerState extends State<VideoSubtitlePlayer> {
  VlcPlayerController? _vlcPlayerController;
  String? _subtitlePath;
  String? _subtitleContent;
  Duration? _position;
  Duration? _duration;
  List<Map<String, dynamic>> _subtitles = [];

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result != null) {
      File videoFile = File(result.files.single.path!);
      _vlcPlayerController = VlcPlayerController.file(
        videoFile,
        hwAcc: HwAcc.full,
        autoPlay: true,
      )..addListener(() {
          final newPosition = _vlcPlayerController!.value.position;
          final newDuration = _vlcPlayerController!.value.duration;
          if (_position != newPosition || _duration != newDuration) {
            setState(() {
              _position = newPosition;
              _duration = newDuration;
            });
          }
        });

      // Add the subtitle if it has already been picked
      if (_subtitlePath != null) {
        _vlcPlayerController!.addSubtitleFromFile(File(_subtitlePath!));
      }

      setState(() {});
    }
  }

  Future<void> _pickSubtitle() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );
    if (result != null) {
      _subtitlePath = result.files.single.path;

      // Update subtitles list and content
      if (_subtitlePath != null) {
        String content = await File(_subtitlePath!).readAsString();
        print('Subtitle content:\n$content'); // Debug print
        _subtitleContent = content;
        _subtitles = parseSubtitles(content);
        print('Parsed subtitles: $_subtitles'); // Debug print
      }

      // Update the UI
      setState(() {});

      // Check if video player is already initialized
      if (_vlcPlayerController != null) {
        // If video player is already initialized, add subtitle to it
        _vlcPlayerController!.addSubtitleFromFile(File(_subtitlePath!));
      } else {
        // If video player is not initialized, do nothing here
      }
    }
  }

  List<Map<String, dynamic>> parseSubtitles(String input) {
    List<Map<String, dynamic>> subtitles = [];
    List<String> lines = input.split('\n');

    for (int i = 0; i < lines.length;) {
      if (lines[i].trim().isEmpty) {
        i++;
        continue;
      }

      int index = int.parse(lines[i].trim());
      i++;

      String timeCode = lines[i].trim();
      List<String> times = timeCode.split(' --> ');
      String startTime = times[0].trim();
      String endTime = times[1].trim();
      i++;

      String text = '';
      while (i < lines.length && lines[i].trim().isNotEmpty) {
        text += lines[i].trim() + '\n';
        i++;
      }

      text = text.trim();

      subtitles.add({
        'index': index,
        'start_time': startTime,
        'end_time': endTime,
        'text': text,
      });

      i++;
    }

    return subtitles;
  }

  Duration _parseTime(String time) {
    final parts = time.split(RegExp(r'[:,]'));
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    final seconds = int.parse(parts[2]);
    final milliseconds = int.parse(parts[3]);
    return Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds);
  }

  @override
  void dispose() {
    _vlcPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitler'),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _pickVideo,
            icon: const Icon(Icons.video_library),
          ),
          IconButton(
            onPressed: _pickSubtitle,
            icon: const Icon(Icons.subtitles),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_vlcPlayerController != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: VlcPlayer(
                  controller: _vlcPlayerController!,
                  aspectRatio: 16 / 9,
                  placeholder: const Center(child: CircularProgressIndicator()),
                ),
              )
            else
              const Text('Pick a video to play'),
            const SizedBox(height: 20),
            if (_vlcPlayerController != null)
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    _vlcPlayerController!.value.isPlaying
                        ? _vlcPlayerController!.pause()
                        : _vlcPlayerController!.play();
                  });
                },
                child: Icon(
                  _vlcPlayerController?.value.isPlaying == true
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
            if (_vlcPlayerController != null &&
                _position != null &&
                _duration != null)
              Slider(
                value: _position?.inSeconds.toDouble() ?? 0.0,
                max: _duration?.inSeconds.toDouble() ?? 0.0,
                onChanged: (value) {
                  _vlcPlayerController!
                      .seekTo(Duration(seconds: value.toInt()));
                },
              ),
            if (_subtitles.isNotEmpty) ...[
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _subtitles.length,
                  itemBuilder: (context, index) {
                    final subtitle = _subtitles[index];
                    return ListTile(
                      leading: Text('${subtitle['index']}'),
                      title: Text(subtitle['start_time'] +
                          ' --> ' +
                          subtitle['end_time']),
                      subtitle: RichText(
                        text: _parseHtml(subtitle['text']),
                      ),
                      onTap: () {
                        _showEditDialog(subtitle);
                      },
                    );

                    // ListTile(
                    //   leading: Text('${subtitle['index']}'),
                    //   title: Text(subtitle['start_time'] +
                    //       ' --> ' +
                    //       subtitle['end_time']),
                    //   subtitle: Text(subtitle['text']),
                    //   onTap: () {
                    //     _showEditDialog(subtitle);
                    //     // if (_vlcPlayerController != null) {
                    //     //   _vlcPlayerController!
                    //     //       .seekTo(parseDuration(subtitle['start_time']));
                    //     // }
                    //   },
                    // );
                  },
                ),
              ),
            ] else ...[
              const Text('No subtitles available'),
            ],
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> subtitle) {
    final startTimeController =
        TextEditingController(text: subtitle['start_time']);
    final endTimeController = TextEditingController(text: subtitle['end_time']);
    final textController = TextEditingController(text: subtitle['text']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Subtitle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: startTimeController,
                  decoration: InputDecoration(labelText: 'Start Time'),
                ),
                TextFormField(
                  controller: endTimeController,
                  decoration: InputDecoration(labelText: 'End Time'),
                ),
                TextFormField(
                  controller: textController,
                  decoration: InputDecoration(labelText: 'Text'),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  subtitle['start_time'] = startTimeController.text;
                  subtitle['end_time'] = endTimeController.text;
                  subtitle['text'] = textController.text;
                });
                _updateSubtitles();
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _updateSubtitles() {
    // Convert the subtitles list back to the SRT format
    String updatedContent = '';
    for (var subtitle in _subtitles) {
      updatedContent += '${subtitle['index']}\n';
      updatedContent +=
          '${subtitle['start_time']} --> ${subtitle['end_time']}\n';
      updatedContent += '${subtitle['text']}\n\n';
    }

    // Save the updated content to the subtitle file
    File(_subtitlePath!).writeAsString(updatedContent);

    // Reload the subtitle file in the VLC player
    _vlcPlayerController?.addSubtitleFromFile(File(_subtitlePath!));
  }

  Duration parseDuration(String time) {
    List<String> parts = time.split(':');
    int hours = int.parse(parts[0]);
    int minutes = int.parse(parts[1]);
    List<String> secParts = parts[2].split(',');
    int seconds = int.parse(secParts[0]);
    int milliseconds = int.parse(secParts[1]);

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: milliseconds,
    );
  }

  TextSpan _parseHtml(String htmlString) {
    final document = html_parser.parse(htmlString);
    final span = _convertNodeToTextSpan(document.body!);
    return TextSpan(
        children: [span],
        style: TextStyle(color: Theme.of(context).textTheme.bodyText1?.color));
  }

  TextSpan _convertNodeToTextSpan(dom.Node node) {
    if (node is dom.Text) {
      return TextSpan(text: node.text);
    }

    if (node is dom.Element) {
      List<TextSpan> children =
          node.nodes.map((child) => _convertNodeToTextSpan(child)).toList();

      switch (node.localName) {
        case 'font':
          return TextSpan(
            children: children,
            style: TextStyle(
              color: node.attributes['color'] != null
                  ? _parseColor(node.attributes['color']!)
                  : null,
            ),
          );
        default:
          return TextSpan(children: children);
      }
    }

    return TextSpan();
  }

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }
}
