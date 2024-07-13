import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:subtitle_editor/constants.dart';
import 'package:subtitle_editor/subtitle.dart';

class SubtitleEditorScreen extends StatefulWidget {
  const SubtitleEditorScreen({super.key});

  @override
  State<SubtitleEditorScreen> createState() => _SubtitleEditorScreenState();
}

class _SubtitleEditorScreenState extends State<SubtitleEditorScreen> {
  VlcPlayerController? _vlcPlayerController;
  String? _subtitlePath;
  String? _subtitleContent;
  Duration? _position;
  Duration? _duration;
  List<Subtitle> _subtitles = [];

  //Scrolling
  ScrollController _scrollController = ScrollController();
  bool _showScrollToTopButton = false;

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

      Future.delayed(const Duration(seconds: 3), () {
        if (_subtitlePath != null) {
          _vlcPlayerController?.addSubtitleFromFile(File(_subtitlePath!));
        }
      });

      // Add the subtitle if it has already been picked

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

        _subtitleContent = content;
        _subtitles = parseSubtitles(content);
      }

      // Update the UI
      setState(() {});

      // Check if video player is already initialized
      if (_vlcPlayerController != null && _subtitlePath != null) {
        // If video player is already initialized, add subtitle to it
        _vlcPlayerController?.addSubtitleFromFile(File(_subtitlePath!));
      } else {
        // If video player is not initialized, do nothing here
      }
    }
  }

  List<Subtitle> parseSubtitles(String input) {
    List<Subtitle> subtitles = [];
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
        text += "${lines[i].trim()}?  \n";
        i++;
      }

      text = text.trim();

      subtitles.add(Subtitle(
          index: index, startTime: startTime, endTime: endTime, text: text));

      i++;
    }

    return subtitles;
  }

  void _showIndexSelectionDialog(BuildContext context) {
    if (_subtitles.isEmpty) {
      // Handle case where subtitles list is empty
      return;
    }

    int selectedIndex = 0; // Default to the first index

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Index'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Select Index: $selectedIndex'),
                  Slider(
                    value: selectedIndex.toDouble(),
                    min: 0,
                    max: (_subtitles.length - 1).toDouble(),
                    divisions: _subtitles.length,
                    onChanged: (value) {
                      setState(() {
                        selectedIndex = value.round();
                      });
                    },
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Assuming _subtitles[selectedIndex] is the target subtitle text
                String targetSubtitleText = _subtitles[selectedIndex].text;
                _scrollToItem(targetSubtitleText);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _scrollToItem(String subtitleText) {
    // Find the index of the item with matching text
    int index =
        _subtitles.indexWhere((subtitle) => subtitle.text == subtitleText);
    if (index != -1) {
      double offset = 0.0;

      // Accumulate heights of preceding items
      for (int i = 0; i < index; i++) {
        // Replace this with your actual item height calculation logic
        double itemHeight = 103; // Example: Replace with actual calculation
        offset += itemHeight;
      }

      // Animate scroll to the calculated offset
      _scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset >= 200) {
        if (!_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = true;
          });
        }
      } else {
        if (_showScrollToTopButton) {
          setState(() {
            _showScrollToTopButton = false;
          });
          print('Hide scroll-to-top button');
        }
      }
    });
  }

  @override
  void dispose() async {
    await _vlcPlayerController?.stopRendererScanning();
    await _vlcPlayerController?.dispose();
    _scrollController.dispose();
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
            onPressed: () {
              _showIndexSelectionDialog(context);
            },
            icon: const Icon(Icons.filter_list),
          ),
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
          children: [
            if (_vlcPlayerController != null)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: VlcPlayer(
                    controller: _vlcPlayerController!,
                    aspectRatio: 16 / 9,
                    placeholder:
                        const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            if (_vlcPlayerController != null)
              Row(
                children: [
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
                  SizedBox(width: 16.w),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _vlcPlayerController?.dispose();
                        _vlcPlayerController = null;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
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
              Expanded(
                child: Scrollbar(
                  controller: _scrollController,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.r),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _subtitles.length,
                    itemBuilder: (context, index) {
                      final subtitle = _subtitles[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: ListTile(
                          leading: Text('${subtitle.index}'),
                          title: Text(
                              "${subtitle.startTime} --> ${subtitle.endTime}"),
                          subtitle: RichText(
                            text: _parseHtml(subtitle.text),
                          ),
                          onTap: () {
                            if (_vlcPlayerController != null) {
                              _vlcPlayerController!
                                  .seekTo(parseDuration(subtitle.startTime));
                            }
                            _showEditDialog(subtitle);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                );
              },
              child: const Icon(Icons.arrow_upward),
            )
          : null,
    );
  }

  void _showEditDialog(Subtitle subtitle) {
    final startTimeController = TextEditingController(text: subtitle.startTime);
    final endTimeController = TextEditingController(text: subtitle.endTime);
    final textController = TextEditingController(text: subtitle.text);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Subtitle'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: startTimeController,
                  decoration: const InputDecoration(labelText: 'Start Time'),
                ),
                TextFormField(
                  controller: endTimeController,
                  decoration: const InputDecoration(labelText: 'End Time'),
                ),
                TextFormField(
                  controller: textController,
                  decoration: const InputDecoration(labelText: 'Text'),
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
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  subtitle.startTime = startTimeController.text;
                  subtitle.endTime = endTimeController.text;
                  subtitle.text = textController.text;
                });
                _updateSubtitles();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
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
      updatedContent += '${subtitle.index}\n';
      updatedContent += '${subtitle.startTime} --> ${subtitle.endTime}\n';
      updatedContent += '${subtitle.text}\n\n';
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

    return const TextSpan();
  }

  Color _parseColor(String colorString) {
    return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
  }
}
