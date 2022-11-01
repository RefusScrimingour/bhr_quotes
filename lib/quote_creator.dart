/*
File: edit_questions.dart
Description: The page where individual questions can be edited, via Quill/VisualEditor
Author: Garv Shah
Created: Sat Jul 23 18:21:21 2022
 */

import 'dart:math';
import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:uuid/uuid.dart';
import 'package:visual_editor/visual-editor.dart';
import 'package:path/path.dart';

import '../../utils/components.dart';

/// A function that processes the image and sends a cropped version.
Future<String?> processImage(BuildContext context, Uint8List bytes, String imageName, String fileExtension) async {
  final cropController = CropController();

  double cropDialogSize = min(
      MediaQuery.of(context).size.width,
      MediaQuery.of(context).size.height) -
      30;

  Future<String?> imageUrl = Future<String?>.value(null);

  await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            title: const Text("Crop Image"),
            children: <Widget>[
              SizedBox(
                width: cropDialogSize,
                height: cropDialogSize - 140,
                child: Crop(
                    image: bytes,
                    controller: cropController,
                    withCircleUi: true,
                    interactive: true,
                    maskColor: DialogTheme.of(context)
                        .backgroundColor ??
                        Theme.of(context)
                            .dialogBackgroundColor,
                    baseColor: DialogTheme.of(context)
                        .backgroundColor ??
                        Theme.of(context)
                            .dialogBackgroundColor,
                    cornerDotBuilder:
                        (size, edgeAlignment) => DotControl(
                        color: Theme.of(context)
                            .colorScheme
                            .primary),
                    onCropped: (image) {
                      imageUrl = uploadFile(image, imageName, fileExtension, context);
                      Navigator.pop(context);
                    }),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(child: SizedBox(height: 5)),
                  ElevatedButton(
                      onPressed: () {
                        imageUrl = uploadFile(bytes, imageName, fileExtension, context);
                        Navigator.pop(context);
                      },
                      child: Text('Skip',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .primaryColorLight))),
                  const Expanded(child: SizedBox(height: 5)),
                  ElevatedButton(
                      onPressed: cropController.crop,
                      child: Text('Crop',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .primaryColorLight))),
                  const Expanded(child: SizedBox(height: 5)),
                ],
              )
            ]);
      });

  return imageUrl;
}

// Uploads files to Firebase and returns the download url
Future<String?> uploadFile(Uint8List file, String name, String fileExtension, BuildContext context) async {
  // Check if the file is too large
  int size = file.lengthInBytes;
  // Checks if the file is above 10mb
  bool tooBig = size > 10000000;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        tooBig ? "Files cannot be larger than 10mb!" : "Uploading file!",
        style: TextStyle(
            color:
            Theme.of(context).primaryColorLight),
      ),
      backgroundColor:
      Theme.of(context).scaffoldBackgroundColor,
    ),
  );

  if (!tooBig) {
    // Storage instance.
    final storage = FirebaseStorage.instance;

    // Sets the storage path to a folder of the user's UID inside the
    // userMedia folder, followed by the file type detected by Mime.
    // For example, if I uploaded a png, it would be
    // userMedia/123456789/image-123456789.png
    Reference ref = storage.ref(
        'userMedia/${FirebaseAuth.instance.currentUser
            ?.uid}/$name-${const Uuid().v4()}$fileExtension');

    // Creates a metadata object from the raw bytes of the image,
    // and then sets it to the reference above
    SettableMetadata metadata =
    SettableMetadata(contentType: lookupMimeType('', headerBytes: file));

    await ref.putData(file, metadata);

    // Gets the URL of this newly created object
    var downloadUrl = ref.getDownloadURL();

    return downloadUrl;
  } else {
    return null;
  }
}

typedef DataCallback = void Function(List<dynamic> data);

/// This is the page where questions can be edited.
//ignore: must_be_immutable
class CreateQuote extends StatefulWidget {
  final DataCallback onSave;
  final List<dynamic> document;
  CreateQuote({Key? key, required this.onSave, required this.document}) : super(key: key);

  @override
  State<CreateQuote> createState() => _CreateQuoteState();
}

class _CreateQuoteState extends State<CreateQuote> {
  late EditorController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    _controller = EditorController(document: DocumentM.fromJson(widget.document));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            header('Create Quote', context, fontSize: 20, backArrow: true, customBackLogic: () {
              widget.onSave(_controller.document.toDelta().toJson());
              Navigator.of(context).pop();
            }),
            Expanded(
              child: VisualEditor(
                scrollController: ScrollController(),
                focusNode: _focusNode,
                controller: _controller,
                config: EditorConfigM(
                  scrollable: true,
                  autoFocus: true,
                  expands: false,
                  padding: const EdgeInsets.all(16.0),
                  readOnly: false,
                  keyboardAppearance: Theme.of(context).brightness,
                ),
              ),
            ),
            EditorToolbar.basic(
              controller: _controller,
              showAlignmentButtons: true,
              multiRowsDisplay: false,
              iconTheme: EditorIconThemeM(
                iconSelectedFillColor: Theme.of(context).colorScheme.primary,
                iconSelectedColor: Colors.white,
              ),
              onImagePickCallback: (file) async {
                return processImage(context, file.readAsBytesSync(), basename(file.path), extension(file.path),);
              },
              onVideoPickCallback: (file) async {
                return uploadFile(file.readAsBytesSync(), basename(file.path), extension(file.path), context);
              },
              webImagePickImpl: (onImagePickCallback) async {
                XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                Uint8List bytes = await image!.readAsBytes();

                return processImage(context, bytes, basename(image.path), extension(image.path));
              },
              webVideoPickImpl: (onVideoPickCallback) async {
                XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
                Uint8List bytes = await video!.readAsBytes();

                return uploadFile(bytes, basename(video.path), extension(video.path), context);
              },
              filePickImpl: (context) async {
                XTypeGroup typeGroup;
                typeGroup = const XTypeGroup(
                    label: 'files', extensions: ['jpg', 'png', 'gif', 'jpeg', 'mp4', 'mov', 'avi', 'mkv', 'webp', 'tif', 'heic']);

                return (await openFile(acceptedTypeGroups: [typeGroup]))?.path;
              },
            ),
          ],
        ),
      ),
    );
  }
}
