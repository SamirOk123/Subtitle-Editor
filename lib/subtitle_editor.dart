import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path/path.dart' as path;

class SubtitleEditor extends StatefulWidget {
  const SubtitleEditor(
      {Key? key, required this.texts, required this.lastFilePath})
      : super(key: key);
  final List<String> texts;
  final String? lastFilePath;

  @override
  State<SubtitleEditor> createState() => _SubtitleEditorState();
}

class _SubtitleEditorState extends State<SubtitleEditor> {
  late List<Map<String, TextEditingController>> _firstLineControllers;
  late List<TextEditingController> _remainingTextControllers;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _firstLineControllers = widget.texts.map((text) {
      List<String> lines = text.split('\n');

      lines.removeAt(0);

      String firstLine = lines.isNotEmpty ? lines[0] : '';

      firstLine = firstLine.replaceAll(' --> ', '     ');

      List<String> timecodes = firstLine.split('     ');
      String startingTime = timecodes.isNotEmpty ? timecodes[0].trim() : '';
      String endingTime = timecodes.length > 1 ? timecodes[1].trim() : '';

      TextEditingController startingTimeController =
          TextEditingController(text: startingTime);
      TextEditingController endingTimeController =
          TextEditingController(text: endingTime);

      return {
        'starting': startingTimeController,
        'ending': endingTimeController
      };
    }).toList();

    _remainingTextControllers = widget.texts.map((text) {
      List<String> lines = text.split('\n');

      lines.removeAt(0);

      if (lines.length > 1) {
        lines.removeAt(0);
      }

      String remainingText = lines.join('\n');

      return TextEditingController(text: remainingText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    String? lastFilePath = widget.lastFilePath;

    // Extract the actual file name using the path package
    String actualFileName =
        lastFilePath != null ? path.basename(lastFilePath) : '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subtitle Editor'),
      ),
      body: Scrollbar(
        thickness: 5,
        controller: _scrollController,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(10),
          itemCount: widget.texts.length - 1,
          itemBuilder: (context, index) {
            int sequenceNumber = index + 1;
            if (index < widget.texts.length - 1) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 8, top: 60),
                    child: Text(
                      '$sequenceNumber',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          color: Colors.black12,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      shadowColor: Colors.black.withOpacity(0.2),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 35,
                                    child: TextField(
                                      style: const TextStyle(fontSize: 13),
                                      decoration: InputDecoration(
                                        labelText: 'Start time',
                                        contentPadding:
                                            const EdgeInsets.only(left: 24),
                                        border: OutlineInputBorder(
                                          borderSide:
                                              const BorderSide(width: 4),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                      controller: _firstLineControllers[index]
                                          ['starting'],
                                      maxLines: null,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: SizedBox(
                                      height: 35,
                                      child: TextField(
                                        style: const TextStyle(fontSize: 13),
                                        decoration: InputDecoration(
                                          labelText: 'End time',
                                          contentPadding:
                                              const EdgeInsets.only(left: 24),
                                          border: OutlineInputBorder(
                                            borderSide:
                                                const BorderSide(width: 4),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        controller: _firstLineControllers[index]
                                            ['ending'],
                                        maxLines: null,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                    onPressed: () {},
                                    icon: const Icon(Icons.more_vert))
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _remainingTextControllers[index],
                              maxLines: null,
                              style: const TextStyle(
                                  fontFamily: 'Malayalam', fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const SizedBox();
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _saveSubtitle(actualFileName);
          Navigator.pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _saveSubtitle(String actualFileName) async {
    List<String> initialSubtitleContent = widget.texts;

    // Retrieve controllers for time codes and text
    List<Map<String, TextEditingController>> firstLineControllers =
        _firstLineControllers;
    List<TextEditingController> remainingTextControllers =
        _remainingTextControllers;

    // Combine time codes and text from controllers to form the edited subtitle
    List<String> editedSubtitles = [];
    for (int i = 0; i < firstLineControllers.length; i++) {
      String timecodes =
          '${firstLineControllers[i]['starting']!.text.trim()} --> ${firstLineControllers[i]['ending']!.text.trim()}';
      String remainingText = remainingTextControllers[i].text.trim();
      editedSubtitles.add('$timecodes\n$remainingText');
    }

    // Join edited subtitles into a single string
    String editedSubtitleContent = editedSubtitles.join('\n\n');

    try {
      // Open Hive box
      await Hive.openBox<String>('subtitles');

      // Get the subtitles box
      Box<String> subtitlesBox = Hive.box<String>('subtitles');

      // Get the existing content, if any
      String? existingContent = subtitlesBox.get(actualFileName);

      // If there is existing content, replace it with the updated content
      if (existingContent != null) {
        subtitlesBox.put(actualFileName, editedSubtitleContent);
      } else {
        // Otherwise, save the new content
        subtitlesBox.put(
            actualFileName,
            initialSubtitleContent.join('\n\n') +
                '\n\n' +
                editedSubtitleContent);
      }

      // Inform the user that the subtitle has been saved
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subtitle saved successfully for $actualFileName'),
        ),
      );
    } catch (e) {
      print('Error saving subtitle: $e');
      // Handle the error as needed
    }
  }
}
