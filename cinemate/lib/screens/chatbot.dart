import 'dart:io';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  List<String> movieNames = [];

  @override
  void initState() {
    super.initState();
    _sendInitialMessage();
  }

// TMDB API anahtarınızı buraya ekleyin
  static const String apiKey = 'f09947e5d5bbc3a4ba0a6e149efb63f9';

  void _generateResponse(String description) async {
    // TMDB API'den öneri almak için gerekli URL'yi oluşturun
    final String url =
        'https://api.themoviedb.org/3/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(description)}';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // İlk öneriyi al
        if (data['results'].isNotEmpty) {
          final movie = data['results'][0];
          final movieTitle = movie['title'] ?? 'Bilgi mevcut değil';

          final ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: "Önerilen film: $movieTitle",
          );

          setState(() {
            messages = [message, ...messages];
          });
        } else {
          final ChatMessage message = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text:
                "Maalesef, belirttiğiniz açıklamaya uygun bir film bulunamadı.",
          );

          setState(() {
            messages = [message, ...messages];
          });
        }
      } else {
        print('API isteğinde bir hata oluştu: ${response.statusCode}');
      }
    } catch (e) {
      print('Bir hata oluştu: $e');
    }
  }

  void _sendInitialMessage() {
    ChatMessage initialMessage = ChatMessage(
      user: geminiUser,
      createdAt: DateTime.now(),
      text: "Merhaba! 1-6 arası film ismi girin, size benzer filmler önereyim.",
    );

    setState(() {
      messages = [initialMessage];
    });
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

    if (chatMessage.text.trim().toLowerCase() == 'bitti') {
      // Kullanıcı 'Bitti' yazarsa, öneri oluştur
      _generateRecommendations();
    } else {
      movieNames.add(chatMessage.text);
      if (movieNames.length >= 6) {
        // 6 veya daha fazla film adı girildiyse, öneri oluştur
        _generateRecommendations();
      } else {
        ChatMessage continueMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text:
              "Devam etmek için daha fazla film adı girebilir veya öneri almak için 'Bitti' yazabilirsiniz.",
        );

        setState(() {
          messages = [continueMessage, ...messages];
        });
      }
    }
  }

  void _generateRecommendations() {
    String question = "Bana ${movieNames.join(', ')} türünde film öner";

    List<String> responseBuffer =
        []; // Yanıt parçalarını biriktirmek için bir liste

    try {
      gemini.streamGenerateContent(question).listen((event) {
        // Yanıt parçalarını buffer'a ekleyin
        String part = event.content?.parts
                ?.fold("", (previous, current) => "$previous${current.text}") ??
            "";
        if (part.isNotEmpty) {
          responseBuffer.add(part);
        }
      }, onDone: () {
        // Yanıt tamamlandığında buffer'daki tüm parçaları birleştirin
        String fullResponse = responseBuffer.join();

        // Tek bir mesaj olarak gönderin
        ChatMessage message = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text: fullResponse,
        );

        setState(() {
          messages = [message, ...messages];
        });

        // Film isimlerini temizle
        movieNames.clear();

        // Kullanıcıya tekrar film önerisi alabileceği mesajı gönder
        ChatMessage continueMessage = ChatMessage(
          user: geminiUser,
          createdAt: DateTime.now(),
          text:
              "Yeni film önerileri almak için yeni film isimleri yazabilirsiniz.",
        );

        setState(() {
          messages = [continueMessage, ...messages];
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
