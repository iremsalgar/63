import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cinemate/services/api.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ChatBotPage extends StatefulWidget {
  const ChatBotPage({super.key});

  @override
  State<ChatBotPage> createState() => _ChatBotPageState();
}

class _ChatBotPageState extends State<ChatBotPage> {
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");


  String? accessToken;

  @override
  void initState() {
    super.initState();
    _fetchAccessToken();
  }

  // Yetkilendirme kodu almak için URL oluşturun ve kullanıcıyı yönlendirin
  void _authorize() async {
    final authorizationUrl = Uri.parse(
        'https://accounts.google.com/o/oauth2/v2/auth?'
            'response_type=code'
            '&client_id=$clientId'
            '&redirect_uri=$redirectUri'
            '&scope=https://www.googleapis.com/auth/cloud-platform'
            '&access_type=offline');

    // Yönlendirme işlemi için uygun bir yöntem kullanın
    // Örneğin, webview kullanarak kullanıcıyı yetkilendirme sayfasına yönlendirin
  }

  // Yetkilendirme kodunu kullanarak erişim token'ı alın
  Future<String> getAccessToken(String authorizationCode) async {
    var url = Uri.parse('https://oauth2.googleapis.com/token');
    var headers = {'Content-Type': 'application/x-www-form-urlencoded'};
    var body = {
      'code': authorizationCode,
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
      'grant_type': 'authorization_code',
    };

    var response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      var jsonResponse = json.decode(response.body);
      return jsonResponse['access_token'];
    } else {
      print('Failed to get access token: ${response.statusCode}');
      print(response.body);
      throw Exception('Failed to get access token');
    }
  }

  Future<void> _fetchAccessToken() async {
    // Kullanıcıyı yetkilendirme kodu almak üzere yönlendirin
    // authorizationCode alındığında getAccessToken çağrılacak
    // authorizationCode'yu doğru şekilde alın ve `_fetchAccessToken` içinde kullanın
    try {
      // Kullanıcıdan yetkilendirme kodunu alın (bu örnekte manuel olarak yerleştirin)
      String authorizationCode = 'AUTHORIZATION_CODE_FROM_USER';
      accessToken = await getAccessToken(authorizationCode);
      print('Access Token: $accessToken');
    } catch (e) {
      print('Failed to get access token: $e');
    }
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

      if (accessToken != null) {
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
      } else {
        print('Access token not available');
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Future<String> generateContent(String question, Uint8List? imageBytes) async {
    try {
      var url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/$modelId:generateContent');
      var headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
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
        print('Response body: ${response.body}');
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
