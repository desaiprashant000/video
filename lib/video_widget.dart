// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:video_player/video_player.dart';
//
// class VideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//
//   VideoPlayerScreen({required this.videoUrl});
//
//   @override
//   _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
// }
//
// class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
//   late VideoPlayerController _videoPlayerController;
//   late ChewieController _chewieController;
//
//   @override
//   void initState() {
//     super.initState();
//     _videoPlayerController = VideoPlayerController.network(widget.videoUrl);
//     _chewieController = ChewieController(
//       videoPlayerController: _videoPlayerController,
//       autoInitialize: true,
//       looping: false,
//       showControls: false,
//     );
//   }
//
//   @override
//   void dispose() {
//     _videoPlayerController.dispose();
//     _chewieController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Chewie(
//           controller: _chewieController,
//         ),
//       ),
//       bottomNavigationBar: Container(
//         color: Colors.black,
//         height: 60,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           children: [
//             IconButton(
//               icon: Icon(Icons.fast_rewind),
//               onPressed: () {
//                 _videoPlayerController.seekTo(
//                     _videoPlayerController.value.position -
//                         Duration(seconds: 10));
//               },
//               color: Colors.white,
//             ),
//             IconButton(
//               icon: Icon(_videoPlayerController.value.isPlaying
//                   ? Icons.pause
//                   : Icons.play_arrow),
//               onPressed: () {
//                 setState(() {
//                   // If the video is playing, pause it.
//                   if (_videoPlayerController.value.isPlaying) {
//                     _videoPlayerController.pause();
//                   } else {
//                     // If the video is paused, play it.
//                     _videoPlayerController.play();
//                   }
//                 });
//               },
//               color: Colors.white,
//             ),
//             IconButton(
//               icon: Icon(Icons.fast_forward),
//               onPressed: () {
//                 _videoPlayerController.seekTo(
//                     _videoPlayerController.value.position +
//                         Duration(seconds: 10));
//               },
//               color: Colors.white,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'dart:async';

import 'package:flick_video_player/flick_video_player.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';

class ChewieDemo extends StatefulWidget {
  ChewieDemo({required this.urls, required this.currentIndex});

  List<String> urls;
  int currentIndex;

  @override
  State<StatefulWidget> createState() {
    return _ChewieDemoState();
  }
}

class _ChewieDemoState extends State<ChewieDemo> {
  late FlickManager flickManager;
  late DataManager dataManager;

  @override
  void initState() {
    super.initState();
    flickManager = FlickManager(
        videoPlayerController:
            VideoPlayerController.network(widget.urls[widget.currentIndex]),
        onVideoEnd: () {
          dataManager.skipToNextVideo(Duration(seconds: 5));
        });

    dataManager = DataManager(
        flickManager: flickManager,
        urls: widget.urls,
        currentPlaying: widget.currentIndex);
  }

  @override
  void dispose() {
    flickManager.dispose();
    super.dispose();
  }

  skipToVideo(String url) {
    flickManager.handleChangeVideo(VideoPlayerController.network(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: VisibilityDetector(
        key: ObjectKey(flickManager),
        onVisibilityChanged: (visibility) {
          if (visibility.visibleFraction == 0 && this.mounted) {
            flickManager.flickControlManager?.autoPause();
          } else if (visibility.visibleFraction == 1) {
            flickManager.flickControlManager?.autoResume();
          }
        },
        child: Column(
          children: [
            Container(
              height: 788,
              child: FlickVideoPlayer(
                flickManager: flickManager,
                preferredDeviceOrientationFullscreen: [
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ],
                flickVideoWithControls: FlickVideoWithControls(
                  controls: CustomOrientationControls(dataManager: dataManager),
                ),
                flickVideoWithControlsFullscreen: FlickVideoWithControls(
                  videoFit: BoxFit.fitWidth,
                  controls: CustomOrientationControls(dataManager: dataManager),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataManager {
  DataManager(
      {required this.flickManager,
      required this.urls,
      required this.currentPlaying});

  int currentPlaying;
  final FlickManager flickManager;
  final List<String> urls;

  Timer? videoChangeTimer;

  String getNextVideo() {
    currentPlaying++;
    return urls[currentPlaying];
  }

  bool hasNextVideo() {
    return currentPlaying != urls.length - 1;
  }

  bool hasPreviousVideo() {
    return currentPlaying != 0;
  }

  skipToNextVideo([Duration? duration]) {
    if (hasNextVideo()) {
      flickManager.handleChangeVideo(
          VideoPlayerController.network(urls[currentPlaying + 1]),
          videoChangeDuration: duration);

      currentPlaying++;
    }
  }

  skipToPreviousVideo() {
    if (hasPreviousVideo()) {
      currentPlaying--;
      flickManager.handleChangeVideo(
          VideoPlayerController.network(urls[currentPlaying]));
    }
  }

  cancelVideoAutoPlayTimer({required bool playNext}) {
    if (playNext != true) {
      currentPlaying--;
    }

    flickManager.flickVideoManager
        ?.cancelVideoAutoPlayTimer(playNext: playNext);
  }
}

class CustomOrientationControls extends StatelessWidget {
  const CustomOrientationControls(
      {Key? key, this.iconSize = 20, this.fontSize = 12, this.dataManager})
      : super(key: key);
  final double iconSize;
  final double fontSize;
  final DataManager? dataManager;

  @override
  Widget build(BuildContext context) {
    FlickVideoManager flickVideoManager =
        Provider.of<FlickVideoManager>(context);

    return Stack(
      children: [
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Container(color: Colors.black38),
          ),
        ),
        Positioned.fill(
          child: FlickShowControlsAction(
            child: FlickSeekVideoAction(
              child: Center(
                child: flickVideoManager.nextVideoAutoPlayTimer != null
                    ? FlickAutoPlayCircularProgress(
                        colors: FlickAutoPlayTimerProgressColors(
                          backgroundColor: Colors.white30,
                          color: Colors.red,
                        ),
                      )
                    : FlickAutoHideChild(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  dataManager!.skipToPreviousVideo();
                                },
                                child: Icon(
                                  Icons.skip_previous,
                                  color: dataManager!.hasPreviousVideo()
                                      ? Colors.white
                                      : Colors.white38,
                                  size: 35,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: FlickPlayToggle(size: 50),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: GestureDetector(
                                onTap: () {
                                  dataManager!.skipToNextVideo();
                                },
                                child: Icon(
                                  Icons.skip_next,
                                  color: dataManager!.hasNextVideo()
                                      ? Colors.white
                                      : Colors.white38,
                                  size: 35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: FlickAutoHideChild(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          FlickCurrentPosition(
                            fontSize: fontSize,
                          ),
                          Text(
                            ' / ',
                            style: TextStyle(
                                color: Colors.white, fontSize: fontSize),
                          ),
                          FlickTotalDuration(
                            fontSize: fontSize,
                          ),
                        ],
                      ),
                      Expanded(
                        child: Container(),
                      ),
                      FlickFullScreenToggle(
                        size: iconSize,
                      ),
                    ],
                  ),
                  FlickVideoProgressBar(
                    flickProgressBarSettings: FlickProgressBarSettings(
                      height: 5,
                      handleRadius: 5,
                      curveRadius: 50,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white38,
                      playedColor: Colors.red,
                      handleColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
