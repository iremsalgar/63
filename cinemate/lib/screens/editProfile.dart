import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _profileNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  File? _profileImageFile;
  String? _profileImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      setState(() {
        _profileNameController.text = userData?['profileName'] ?? '';
        _usernameController.text = userData?['username'] ?? '';
        _emailController.text = userData?['email'] ?? '';
        _profileImageUrl = userData?['profileImage'];
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      String? imageUrl = _profileImageUrl;

      if (_profileImageFile != null) {
        imageUrl = await _uploadProfileImage(_profileImageFile!);
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'profileName': _profileNameController.text,
        'username': _usernameController.text,
        'email': _emailController.text,
        if (imageUrl != null) 'profileImage': imageUrl,
      });

      Navigator.pop(context);
    }
  }

  Future<String?> _uploadProfileImage(File image) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final profileImagesRef = storageRef
          .child('profile_images/${DateTime.now().toIso8601String()}');
      await profileImagesRef.putFile(image);
      final downloadUrl = await profileImagesRef.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _showImageSelectionDialog() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance.ref().child('profile_images');
      final ListResult result = await storageRef.listAll();

      final List<String> imageUrls = [];
      for (final ref in result.items) {
        final url = await ref.getDownloadURL();
        imageUrls.add(url);
      }

      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Profile Image'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      final imageUrl = imageUrls[index];
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _profileImageUrl = imageUrl;
                            _profileImageFile =
                                null; // Ensure no local file is set
                          });
                          // Save the selected image URL to Firestore
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .update({
                              'profileImage': imageUrl,
                            });
                          }
                          Navigator.of(context).pop();
                        },
                        child: Image.network(imageUrl, fit: BoxFit.cover),
                      );
                    },
                  ),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading images from storage: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Choose Image Source'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _pickImage();
                        },
                        child: const Text('Pick from Gallery'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showImageSelectionDialog();
                        },
                        child: const Text('Select from Storage'),
                      ),
                    ],
                  ),
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _profileImageFile != null
                    ? FileImage(_profileImageFile!)
                    : _profileImageUrl != null
                        ? NetworkImage(_profileImageUrl!)
                        : const AssetImage(
                                'assets/images/default_profile_image.png')
                            as ImageProvider,
                child: _profileImageFile == null
                    ? const Icon(Icons.camera_alt, size: 50, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _profileNameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
              ),
            ),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
