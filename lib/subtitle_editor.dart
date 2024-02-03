import 'package:flutter/material.dart';

class SubtitleEditor extends StatefulWidget {
  const SubtitleEditor({Key? key, required this.texts}) : super(key: key);
  final List<String> texts;

  @override
  State<SubtitleEditor> createState() => _SubtitleEditorState();
}

class _SubtitleEditorState extends State<SubtitleEditor> {
  late List<Map<String, TextEditingController>> _firstLineControllers;
  late List<TextEditingController> _remainingTextControllers;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      backgroundColor: const Color(0xffF2F0E3),
      appBar: AppBar(
        title: const Text('Subtitle Editor'),
        backgroundColor: const Color(0xff922C29),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: widget.texts.length,
        itemBuilder: (context, index) {
          int sequenceNumber = index + 1;

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
                              child: SizedBox(
                                height: 35,
                                child: TextField(
                                  style: const TextStyle(fontSize: 13),
                                  decoration: InputDecoration(
                                    labelText: 'Start time',
                                    contentPadding:
                                        const EdgeInsets.only(left: 24),
                                    border: OutlineInputBorder(
                                      borderSide: const BorderSide(width: 4),
                                      borderRadius: BorderRadius.circular(8),
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
                                        borderSide: const BorderSide(width: 4),
                                        borderRadius: BorderRadius.circular(8),
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
                            fontFamily: 'Malayalam',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff922C29),
        onPressed: () {
          // List<String> updatedTexts = List.generate(widget.texts.length, (index) {
          //   String firstLine = _firstLineControllers[index].text;
          //   String remainingText = _remainingTextControllers[index].text;
          //   return '$firstLine\n$remainingText';
          //  });

          Navigator.pop(context);
        },
        child: const Icon(Icons.save),
      ),
    );
  }
}
