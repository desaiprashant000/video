import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video/video_widget.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoPlayerCustum extends StatefulWidget {
  const VideoPlayerCustum({Key? key}) : super(key: key);

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayerCustum> {
  List<String> _videos = [];
  List<String?> _thumbnails = [];
  HashSet selectItems = HashSet();
  bool isMultiSelectionEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  _loadVideos() async {
// Get the internal storage directory
    final storage = await getExternalStorageDirectory();
// Navigate to the custom album directory
    final album = Directory("/storage/emulated/0/Movies/RPSApp");
    //final album = Directory('${storage!.path}/MyVideos');
    final files = album.listSync(recursive: true);
    print('files = $files');
// Filter the list of files to only include .mp4 and .mkv files
    final videoFiles = files.where((f) =>
        f is File && (f.path.endsWith('.mp4') || f.path.endsWith('.mkv')));
    print('videoFiles = $videoFiles');
// Do something with the list of video files
    for (var file in videoFiles) {
      print(file.path);
    }
    setState(() {
      _videos = videoFiles.map((file) => file.path).toList();
      generateThumbnail();
    });
    // _videos = videoFiles.map((file) => file.path).toList();
    // generateThumbnail();
  }

  Future<File> copyAssetFile(String assetFileName) async {
    Directory tempDir = await getTemporaryDirectory();
    final byteData = await rootBundle.load(assetFileName);

    File videoThumbnailFile = File("${tempDir.path}/$assetFileName")
      ..createSync(recursive: true)
      ..writeAsBytesSync(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    return videoThumbnailFile;
  }

  void generateThumbnail() async {
    List<String?> exThumnails = [];
    for (int i = 0; i < _videos.length; i++) {
      exThumnails.add(null);
    }

    print("exThumnails before..........= $exThumnails and _videos = $_videos");
    for (int i = 0; i < _videos.length; i++) {
      var exThumbnailPath = await VideoThumbnail.thumbnailFile(
        video: _videos[i],
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.WEBP,
        // maxHeight: 300,
        // maxWidth: 300,
        quality: 100,
      );

      print("exThumbnailPath = $exThumbnailPath");
      print("exThumnails[$i] before.....= ${exThumnails[i]}");
      exThumnails[i] = exThumbnailPath;
      print("exThumnails[$i] = ${exThumnails[i]}");
    }
    print("exThumnails after..........= $exThumnails");

    setState(() {
      _thumbnails = exThumnails;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(selectItems.length < 1
              ? "Multi Selection"
              : "${selectItems.length} item selected"),
          leading: isMultiSelectionEnabled
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      isMultiSelectionEnabled = false;
                      selectItems.clear();
                    });
                  },
                  icon: Icon(Icons.close))
              : null,
          // title: Text(isMultiSelectionEnabled
          //     ? getSelectedItemCount()
          //     : "Select video"),
          actions: [
            Visibility(
                visible: isMultiSelectionEnabled,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (selectItems.length == _videos.length) {
                        selectItems.clear();
                      } else {
                        for (int index = 0; index < _videos.length; index++) {
                          selectItems.add(_videos[index]);
                        }
                      }
                    });
                  },
                  icon: Icon(
                    Icons.select_all_sharp,
                    color: (selectItems.length == _videos.length)
                        ? Colors.black
                        : Colors.white,
                  ),
                )),
            selectItems.length < 1
                ? Container()
                : InkWell(
                    onTap: () {
                      setState(() {
                        while (selectItems.length > 0) {
                          var lastSelectedItem = selectItems.last;
                          File(lastSelectedItem).delete();
                          _videos.remove(lastSelectedItem);
                          selectItems.remove(lastSelectedItem);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(Icons.delete),
                    )),
          ],
        ),
        body: GridView.count(
          crossAxisCount: 3,
          childAspectRatio: 1,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          children: _videos.map((String path) {
            return getGridItem(path);
          }).toList(),
        ));
  }

  // String getSelectedItemCount() {
  //   return selectItems.isNotEmpty
  //       ? selectItems.length.toString() + " item selected"
  //       : "No item selected";
  // }

  void doMultiSelection(String path) {
    if (isMultiSelectionEnabled) {
      setState(() {
        if (selectItems.contains(path)) {
          selectItems.remove(path);
        } else {
          selectItems.add(path);
        }
      });
    } else {}
  }

  GridTile getGridItem(String path) {
    print("_thumbnails = $_thumbnails and _videos = $_videos");
    var index = _videos.indexOf(path);

    if (_thumbnails.length == 0) {
      return GridTile(
          child: Center(
        child: Image.asset("image/SyHq1.png"),
      ));
    }
    return GridTile(
      child: InkWell(
        onTap: () {
          doMultiSelection(path);
        },
        onLongPress: () {
          isMultiSelectionEnabled = true;
          doMultiSelection(path);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            InkWell(
              onTap: () {
                print("hello");
                setState(() {
                  if (isMultiSelectionEnabled) {
                    doMultiSelection(path);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ChewieDemo(
                            urls: _videos, currentIndex: index,
                          );
                        },
                      ),
                    );
                  }
                });
              },
              child: Image.file(
                File(_thumbnails[index]!),
                alignment: Alignment.center,
                height: double.infinity,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.black45,
              child: Icon(
                Icons.play_arrow,
                size: 25,
                color: Colors.white,
              ),
            ),
            Visibility(
              visible: selectItems.contains(path),
              child: const Align(
                alignment: Alignment.topRight,
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
