import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:photo_manager/photo_manager.dart';

import 'image_item_widget.dart';

class PickScreen extends StatefulWidget {
  const PickScreen({Key? key}) : super(key: key);

  @override
  State<PickScreen> createState() => _PickScreenState();
}

class _PickScreenState extends State<PickScreen> {
  bool _isLoading = false;
  List<AssetEntity> _assets = [];
  List<File> displayImage = [];
  Set<int> selectedImageIndices = {};

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _fetchNewMedia();
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
                    margin: const EdgeInsets.all(10),
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
          print('selected images');
          selectedImageIndices.forEach((element) {
            print(element);
          });
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
      print('fail auth');
    }
  }

  Future<String> getFilePath(AssetEntity asset) async {
    final file = await asset.file;
    return file?.path ?? '';
  }
}
