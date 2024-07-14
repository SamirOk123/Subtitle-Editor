import 'dart:io';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
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
  // ScrollController _scrollController = ScrollController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

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
        text += "${lines[i].trim()}  \n";
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

    int selectedIndex = 1; // Default to the first index

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Jump to line'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedIndex.toString(),
                    style: TextStyle(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Slider(
                    value: selectedIndex.toDouble(),
                    min: 1,
                    max: (_subtitles.length).toDouble(),
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
                // String targetSubtitleText = _subtitles[selectedIndex].text;

                _itemScrollController.scrollTo(
                    index: selectedIndex - 1,
                    curve: Curves.fastOutSlowIn,
                    duration: const Duration(seconds: 1));
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _itemPositionsListener.itemPositions.addListener(_scrollListener);
  }

  void _scrollListener() {
    // Check if the user has scrolled down
    final firstVisibleIndex =
        _itemPositionsListener.itemPositions.value.first.index;
    if (firstVisibleIndex > 5 && !_showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = true;
      });
    } else if (firstVisibleIndex <= 5 && _showScrollToTopButton) {
      setState(() {
        _showScrollToTopButton = false;
      });
    }
  }

  @override
  void dispose() async {
    await _vlcPlayerController?.stopRendererScanning();
    await _vlcPlayerController?.dispose();
    _itemPositionsListener.itemPositions.removeListener(_scrollListener);

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
                child: ScrollablePositionedList.builder(
                  // scrollOffsetListener: _scrollOffsetListener,
                  itemScrollController: _itemScrollController,
                  itemPositionsListener: _itemPositionsListener,
                  padding: EdgeInsets.all(16.r),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _subtitles.length,
                  itemBuilder: (context, index) {
                    final subtitle = _subtitles[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: InkWell(
                        onTap: () {
                          if (_vlcPlayerController != null) {
                            _vlcPlayerController!
                                .seekTo(parseDuration(subtitle.startTime));
                          }
                          _showEditDialog(subtitle);
                        },
                        child: Row(
                          children: [
                            Text(
                              subtitle.index.toString(),
                              style: TextStyle(
                                fontSize: 12.sp,
                              ),
                            ),
                            SizedBox(width: 16.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${subtitle.startTime} --> ${subtitle.endTime}",
                                ),
                                SizedBox(height: 8.h),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.7,
                                  child:
                                      RichText(text: _parseHtml(subtitle.text)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _showScrollToTopButton
          ? FloatingActionButton(
              onPressed: () {
                _itemScrollController.scrollTo(
                    index: 0, duration: const Duration(seconds: 1));
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
          content: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        "Line: ${subtitle.index} (${calculateDuration(subtitle.startTime, subtitle.endTime)})"),
                    GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: const Icon(Icons.close)),
                  ],
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: textController,
                  style: TextStyle(fontSize: 12.sp),
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 12.h,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    enabledBorder:
                        OutlineInputBorder(borderSide: BorderSide.none),
                    filled: true,
                    fillColor: kPrimaryColor.withOpacity(0.1),
                  ),
                  maxLines: 6,
                ),
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 80.w,
                      height: 30.h,
                      child: TextFormField(
                        style: TextStyle(fontSize: 9.sp, color: Colors.white),
                        controller: startTimeController,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xff888888),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          subtitle.startTime = startTimeController.text;
                          subtitle.endTime = endTimeController.text;
                          subtitle.text = textController.text;
                        });
                        _updateSubtitles();
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        Icons.save,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(
                      width: 80.w,
                      height: 30.h,
                      child: TextFormField(
                          style: TextStyle(fontSize: 9.sp, color: Colors.white),
                          controller: endTimeController,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: const Color(0xff888888),
                          )),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.arrow_back_ios_rounded,
                            size: 12.sp,
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12.sp,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: kPrimaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.r),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.format_bold_rounded,
                            size: 12.sp,
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.format_italic_rounded,
                            size: 12.sp,
                          ),
                          SizedBox(width: 12.w),
                          Icon(
                            Icons.palette,
                            size: 12.sp,
                          ),
                          SizedBox(width: 12.w),
                          GestureDetector(
                            onTap: () {
                              textController.clear();
                            },
                            child: Icon(
                              Icons.clear_all_rounded,
                              size: 12.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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

  String calculateDuration(String startTime, String endTime) {
    // Function to parse the time string into a DateTime object
    DateTime parseTime(String time) {
      List<String> parts = time.split(',');
      List<String> timeParts = parts[0].split(':');
      int hours = int.parse(timeParts[0]);
      int minutes = int.parse(timeParts[1]);
      int seconds = int.parse(timeParts[2]);
      int milliseconds = int.parse(parts[1]);

      return DateTime(0, 1, 1, hours, minutes, seconds, milliseconds);
    }

    // Parse start and end times
    DateTime startDateTime = parseTime(startTime);
    DateTime endDateTime = parseTime(endTime);

    // Calculate the duration between the two times
    Duration duration = endDateTime.difference(startDateTime);

    // Convert duration to minutes and seconds
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;

    // Create the formatted string
    String formattedDuration = '';
    if (minutes > 0) {
      formattedDuration += "${minutes} min${minutes != 1 ? 's' : ''} ";
    }
    if (seconds > 0) {
      formattedDuration += "${seconds} sec${seconds != 1 ? 's' : ''}";
    }

    return formattedDuration.trim();
  }
}
