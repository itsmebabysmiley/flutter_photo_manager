import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/widget/image_item_widget.dart';
import 'package:video_player/video_player.dart';

import 'pick_screen.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<AssetEntity> _assets = [];
  List<File> displayImage = [];
  Set<int> selectedImageIndices = {};
  bool _isLoading = false;
  List<MediaFile> _pickedMedia = [];
  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: buildFromMe(context));
  }

  Widget buildFromMe(BuildContext context) {
    print("length");
    print(_pickedMedia.length);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Photo Manager from me'),
      ),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, // Number of columns
          crossAxisSpacing: 4.0,
          mainAxisSpacing: 4.0,
        ),
        itemCount: _pickedMedia.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.all(10),
            height: 100,
            width: 100,
            color: Colors.grey,
            child: _pickedMedia[index].fileType == FileType.video
                ? _controller != null && _controller!.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      )
                    : Container()
                : Image.file(
                    File(_pickedMedia[index].file),
                    fit: BoxFit.cover,
                  ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final pickedImages =
              await Navigator.of(context).push<List<MediaFile>>(
            MaterialPageRoute(builder: (context) => PickScreen()),
          );

          if (pickedImages == null) {
            print('no data');
          } else {
            print('data from pick screen');
            print(pickedImages.length);
            setState(() {
              _pickedMedia = pickedImages;
            });
            for (MediaFile media in pickedImages) {
              if (media.fileType == FileType.video) {
                await _playVideo(File(media.file));
              }
            }
            print('_pickerMeida');
            print(_pickedMedia.length);
            // setState(() async {
            //   _pickedMedia = pickedImages;

            // });
          }
        },
        child: Icon(Icons.photo_library),
      ),
    );
  }

  Widget buildFromSample(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Manager from sample'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : GridView.custom(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
              ),
              childrenDelegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) {
                  final AssetEntity entity = _assets[index];
                  return ImageItemWidget(
                    key: ValueKey<int>(index),
                    entity: entity,
                    option:
                        const ThumbnailOption(size: ThumbnailSize.square(200)),
                    onTap: () {
                      print('tap');
                    },
                  );
                },
                childCount: _assets.length,
                findChildIndexCallback: (Key key) {
                  // Re-use elements.
                  if (key is ValueKey<int>) {
                    return key.value;
                  }
                  return null;
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _fetchNewMedia();
        },
        child: Icon(Icons.photo_library),
      ),
    );
  }

  _fetchNewMedia() async {
    setState(() {
      _isLoading = true;
    });
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (_ps.isAuth) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true);
      print(albums[0]);
      List<AssetEntity> media = await albums[0]
          .getAssetListPaged(page: 0, size: 10); //preloading files
      print(media.toList());
      List<String> filePaths = [];
      for (var asset in media) {
        final filePath = await getFilePath(asset);
        filePaths.add(filePath);
      }

      setState(() {
        _assets = media;
        displayImage
            .addAll(filePaths.map((filePath) => File(filePath)).toList());
        _isLoading = false;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
    }
  }

  Future<String> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path ?? '';
  }

  Future<void> _pickAsset() async {
    final result = await PhotoManager.requestPermissionExtend();
    if (!mounted) {
      return;
    }
    // Further requests can be only proceed with authorized or limited.
    if (!result.hasAccess) {
      showToast('Permission is not accessible.');
      return;
    }
    if (result.hasAccess) {
      final assets = await PhotoManager.getAssetPathList(type: RequestType.all);
      final assestsList = assets.toList();
      assestsList.forEach(
        (element) => print(element),
      );
      List<AssetEntity> media =
          await assets[0].getAssetListPaged(size: 60, page: 0);
      final mediaList = media.toList();
      setState(() {
        _assets = media;
      });
    } else {
      print('Permission denied');
    }
  }

  Future<void> _playVideo(File? file) async {
    if (file != null && mounted) {
      await _disposeVideoController();
      late VideoPlayerController controller;
      controller = VideoPlayerController.file(File(file.path));

      _controller = controller;
      // In web, most browsers won't honor a programmatic call to .play
      // if the video has a sound track (and is not muted).
      // Mute the video so it auto-plays in web!
      // This is not needed if the call to .play is the result of user
      // interaction (clicking on a "play" button, for example).
      const double volume = 1.0;
      await controller.setVolume(volume);
      await controller.initialize();
      await controller.setLooping(false);
      // await controller.play();
      setState(() {});
    }
  }

  Future<void> _disposeVideoController() async {
    if (_toBeDisposed != null) {
      await _toBeDisposed!.dispose();
    }
    _toBeDisposed = _controller;
    _controller = null;
  }
}
