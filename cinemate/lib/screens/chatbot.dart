import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  final Gemini gemini = Gemini.instance;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("ChatBot"),
        backgroundColor: Colors.amber[700],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
      messageOptions: const MessageOptions(
        containerColor: Colors.grey,
        currentUserContainerColor: Colors.black,
      ),
      inputOptions: InputOptions(
        inputTextStyle: const TextStyle(color: Colors.black),
        trailing: [
          IconButton(
            onPressed: sendMediaMessage,
            icon: const Icon(Icons.image),
          ),
        ],
        inputMaxLines: 1,
        inputTextDirection: TextDirection.ltr,
        inputDecoration: InputDecoration(
          hintText: "Film Adını Giriniz",
          filled: true,
          fillColor: Colors.grey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10.0),
            borderSide: BorderSide.none,
          ),
        ),
        autocorrect: true,
      ),
      currentUser: currentUser,
      onSend: _sendMessage,
      messages: messages,
    );
  }

  void _sendMessage(ChatMessage chatMessage) {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    String movieName = chatMessage.text;
    String question = "Bana $movieName türünde film öner";

    _generateResponse(question);
  }

  void _generateResponse(String question) {
    try {
      gemini.streamGenerateContent(question).listen((event) {
        String response = event.content?.parts
                ?.fold("", (previous, current) => "$previous${current.text}") ??
            "";

        ChatMessage message = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: response,
        );

        setState(() {
          messages = [message, ...messages];
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
    );
    if (file != null) {
      ChatMedia media = ChatMedia(
        url: file.path,
        fileName: file.name,
        type: MediaType.image,
      );

      ChatMessage mediaMessage = ChatMessage(
        user: currentUser,
        createdAt: DateTime.now(),
        text: "Describe this picture",
        medias: [media],
      );

      setState(() {
        messages = [mediaMessage, ...messages];
      });

      _generateResponse(mediaMessage.text);
    }
  }
}
