import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/softkey_focus.dart';
import 'message_widget.dart';

class ChatWidget extends StatefulWidget {
  const ChatWidget({
    required this.apiKey,
    super.key,
  });

  final String apiKey;

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> {
  String _apiKey = "";
  late final GenerativeModel _model;
  late final GenerativeModel _visionModel;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  final List<ContentEntry> _generatedContent = [];

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.get('API_KEY');
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: widget.apiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-pro-vision',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(
          milliseconds: 750,
        ),
        curve: Curves.easeOutCirc,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      contentPadding: const EdgeInsets.all(15),
      hintText: 'Enter a prompt...',
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(
          Radius.circular(14),
        ),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _apiKey.isNotEmpty
                ? ListView.builder(
              controller: _scrollController,
              itemBuilder: (context, idx) {
                final content = _generatedContent[idx];
                return MessageWidget(
                  text: content.text,
                  image: content.image,
                  isFromUser: content.fromUser,
                );
              },
              itemCount: _generatedContent.length,
            )
                : ListView(
              children: const [
                Text(
                  'No API key found. Please provide an API Key using '
                      "'--dart-define' to set the 'API_KEY' declaration.",
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 25,
              horizontal: 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: false,
                    focusNode: _textFieldFocus,
                    decoration: textFieldDecoration,
                    controller: _textController,
                    onSubmitted: _sendChatMessage,
                  ),
                ),
                const SizedBox.square(dimension: 15),
                IconButton(
                  onPressed: !_loading
                      ? () async {
                    _pickAndSendImage(_textController.text);
                     // _sendImagePrompt(_textController.text);
                  }
                      : null,
                  icon: Icon(
                    Icons.image,
                    color: _loading
                        ? Theme.of(context).colorScheme.secondary
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (!_loading)
                  IconButton(
                    onPressed: () async {
                      _sendChatMessage(_textController.text);
                    },
                    icon: Icon(
                      Icons.send,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  const CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendChatMessage(String message) async {
    hideKeyboard(context);
    setState(() {
      _loading = true;
    });

    try {
      _generatedContent.add(ContentEntry(image: null, text: message, fromUser: true));
      final response = await _chat.sendMessage(
        Content.text(message),
      );
      final text = response.text;
      _generatedContent.add(ContentEntry(image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  void _showError(String message) {
    hideKeyboard(context);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            )
          ],
        );
      },
    );
  }

  Future<void> _sendImagePrompt(String message) async {
    setState(() {
      _loading = true;
    });
    try {
      ByteData catBytes = await rootBundle.load('assets/images/cat.jpg');
      ByteData sconeBytes = await rootBundle.load('assets/images/scones.jpg');
      final content = [
        Content.multi([
          TextPart(message),
          // The only accepted mime types are image/*.
          DataPart('image/jpeg', catBytes.buffer.asUint8List()),
          DataPart('image/jpeg', sconeBytes.buffer.asUint8List()),
        ])
      ];
      _generatedContent.add(ContentEntry(
        image: Image.asset("assets/images/cat.jpg"),
        text: message,
        fromUser: true,
      ));

      _generatedContent.add(ContentEntry(
        image: Image.asset("assets/images/scones.jpg"),
        text: null,
        fromUser: true,
      ));

      var response = await _visionModel.generateContent(content);
      var text = response.text;
      _generatedContent.add(ContentEntry(image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      } else {
        setState(() {
          _loading = false;
          _scrollDown();
        });
      }
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
      });
      _textFieldFocus.requestFocus();
    }
  }

  Future<List<DataPart>> _getImageDataParts(List<XFile> images) async {
    var imageBytes = await Future.wait(
      images.map((image) async {
        var bytes = await image.readAsBytes();
        return DataPart('image/jpeg', bytes);
      }),
    );
    return imageBytes;
  }

  Future<void> _pickAndSendImage(String message) async {
    hideKeyboard(context);
    final ImagePicker picker = ImagePicker();
    List<XFile>? images = await picker.pickMultiImage();

    if (images.isEmpty) {
      return; // No image selected
    }

    setState(() {
      _loading = true;
    });

    try {
      List<DataPart> imageDataParts = await _getImageDataParts(images); // Fetch image data parts asynchronously

      final content = Content.multi([
        TextPart(message),
        ...imageDataParts,
      ]);

      // Assuming you add the images to your local state for display
      for (var image in images) {
        File file = File(image.path);
        _generatedContent.add(ContentEntry(
            image: Image.file(file),
            text: message,
            fromUser: true
        ));
      }

      var response = await _visionModel.generateContent([content]);
      var text = response.text;
      _generatedContent.add(ContentEntry(image: null, text: text, fromUser: false));

      if (text == null) {
        _showError('No response from API.');
        return;
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        _loading = false;
      });
      _showError(e.toString());
    } finally {
      _textController.clear();
      setState(() {
        _loading = false;
        _scrollDown();
      });
      // _textFieldFocus.requestFocus();
    }
  }

}


class ContentEntry {
  final Image? image;
  final String? text;
  final bool fromUser;

  ContentEntry({this.image, this.text, required this.fromUser});
}
