import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class MediaFile {
  final FileType fileType;
  final String file;

  MediaFile({required this.fileType, required this.file});
}

enum FileType {
  image,
  video,
}

class PickScreen extends StatefulWidget {
  const PickScreen({Key? key}) : super(key: key);

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  bool _isLoading = false;
  List<AssetEntity> _assets = [];
  List<String> displayImage = [];
  Set<int> selectedImageIndices = {};
  final List<MediaFile> _selectedMedia = [];

  VideoPlayerController? _controller;
  VideoPlayerController? _toBeDisposed;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
  }

  @override
  void dispose() {
    super.dispose();
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
      await controller.setLooping(true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick photo/video'),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: displayImage.length,
              itemBuilder: (context, index) {
                final isVideo = isVideoFile(File(displayImage[index]));
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedImageIndices.contains(index)) {
                        selectedImageIndices.remove(index);

                        _selectedMedia.remove(MediaFile(
                            fileType: isVideo ? FileType.video : FileType.image,
                            file: displayImage[index]));
                      } else {
                        selectedImageIndices.add(index);
                        _selectedMedia.add(MediaFile(
                            fileType: isVideo ? FileType.video : FileType.image,
                            file: displayImage[index]));
                      }
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedImageIndices.contains(index)
                            ? Colors.blue // Border color for selected images
                            : Colors.transparent, // No border for other images
                        width: 3.0,
                      ),
                    ),
                    child: isVideo
                        ? _controller != null &&
                                _controller!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              )
                            : Container()
                        : Image.file(
                            File(displayImage[index]),
                            fit: BoxFit.cover,
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          print('selected images');
          Navigator.of(context).pop(_selectedMedia);
        },
        child: Icon(Icons.done_outline),
      ),
    );
  }

  bool isVideoFile(File file) {
    final videoExtensions = [
      '.mp4',
      '.mov',
      '.avi',
      '.mkv'
    ]; // Add more video extensions if needed
    final extension = file.path.toLowerCase();
    print('isVideo');
    print(file.path);
    print(videoExtensions
        .any((videoExtension) => extension.endsWith(videoExtension)));
    return videoExtensions
        .any((videoExtension) => extension.endsWith(videoExtension));
  }

  _fetchNewMedia() async {
    setState(() {
      _isLoading = true;
    });
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (!mounted) {
      return;
    }
    // Further requests can be only proceed with authorized or limited.
    if (!_ps.hasAccess) {
      print('Permission is not accessible.');
      return;
    }
    if (_ps.isAuth) {
      // success
//load the album list
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(onlyAll: true); //all type
      List<AssetEntity> media = await albums[0] //get recent albums.
          .getAssetListPaged(page: 0, size: 10); //preloading 10 files

      List<String> filePaths = [];
      for (var asset in media) {
        final filePath = await getFilePath(asset);
        filePaths.add(filePath);
        bool isv = isVideoFile(File(filePath));
        if (isv) {
          await _playVideo(File(filePath));
        }
      }
      setState(() {
        _assets = media;
        displayImage.addAll(filePaths);
        _isLoading = false;
      });
    } else {
      // fail
      /// if result is fail, you can call `PhotoManager.openSetting();`  to open android/ios applicaton's setting to get permission
      print('fail auth');
    }
  }

  Future<String> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path ?? '';
  }
}
