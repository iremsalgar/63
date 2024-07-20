import 'dart:convert'; // JSON kodlama ve çözme için
import 'dart:io'; // Dosya işlemleri için
import 'dart:typed_data'; // Byte verileri için
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http; // HTTP istekleri için

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  final String apiKey = 'AIzaSyBRSZUxijXkKhpQAgflnCzDRLWbnNM1-0E'; // API anahtarınızı buraya girin
  final String modelId = 'your_custom_model_id'; // Özel model ID'nizi buraya girin

  @override
  void initState() {
    super.initState();
  }

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
          hintText: "Lütfen Dizi veya Film Adlarını Giriniz",
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

  void _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    try {
      String question = chatMessage.text;
      Uint8List? imageBytes;
      if (chatMessage.medias?.isNotEmpty ?? false) {
        imageBytes = await File(chatMessage.medias!.first.url).readAsBytes();
      }

      String response = await generateContent(question, imageBytes);

      if (response.isNotEmpty) {
        ChatMessage responseMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: response,
        );
        setState(() {
          messages = [responseMessage, ...messages];
        });
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<String> generateContent(String question, Uint8List? imageBytes) async {
    try {
      var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/tunedModels/moviesserieschatbot-htkug6l95c3a:generateContent?key=$apiKey');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };
      var body = json.encode({
        'prompt': question,
        'image': imageBytes != null ? base64Encode(imageBytes) : null,
        'maxTokens': 150, // Yanıt uzunluğunu ayarlayın
      });

      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        return jsonResponse['choices'][0]['text'] ?? 'No response';
      } else {
        print('Failed to generate content: ${response.statusCode}');
        return 'Error generating content';
      }
    } catch (e) {
      print('Error generating content: $e');
      return 'Error generating content';
    }
  }

  void sendMediaMessage() async {
    try {
      ImagePicker picker = ImagePicker();
      XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (file != null) {
        ChatMessage mediaMessage = ChatMessage(
          user: currentUser,
          createdAt: DateTime.now(),
          text: "Describe this picture",
          medias: [
            ChatMedia(url: file.path, fileName: "", type: MediaType.image)
          ],
        );
        _sendMessage(mediaMessage);
      }
    } catch (e) {
      print('Error picking media: $e');
    }
  }
}
