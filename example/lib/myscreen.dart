import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_example/widget/image_item_widget.dart';

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

  _fetchNewMedia() async {
    setState(() {
      _isLoading = true;
    });
    final PermissionState _ps = await PhotoManager.requestPermissionExtend();
    if (_ps.isAuth) {
      // success
//load the album list
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: buildFromMe(context));
  }

  Widget buildFromMe(BuildContext context) {
    print('okay');
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo Manager from me'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, // Number of columns
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: displayImage.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selectedImageIndices.contains(index)) {
                        selectedImageIndices.remove(index);
                      } else {
                        selectedImageIndices.add(index);
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selectedImageIndices.contains(index)
                            ? Colors.blue // Border color for selected images
                            : Colors.transparent, // No border for other images
                        width: 3.0,
                      ),
                    ),
                    child: ImageItemWidget(
                      key: ValueKey<int>(index),
                      entity: _assets[
                          index], // Replace _assets[index] with your asset data
                      option: ThumbnailOption(size: ThumbnailSize.square(200)),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // _fetchNewMedia();
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => PickScreen()));
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
}
