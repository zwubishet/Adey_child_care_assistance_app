import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:adde/l10n/arb/app_localizations.dart';
import 'package:adde/pages/community/post_model.dart';
import 'package:adde/pages/community/post_provider.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key, this.post});

  final Post? post;

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? motherId;
  String? fullName;
  String? profileUrl;
  bool _isLoading = true;
  File? _imageFile;
  final _picker = ImagePicker();
  bool _hasFetchedUserData = false; // Track if user data has been fetched

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _titleController.text = widget.post!.title;
      _contentController.text = widget.post!.content;
    }
    // Do not call _fetchUserData here; move to didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasFetchedUserData) {
      _fetchUserData();
      _hasFetchedUserData = true; // Prevent repeated calls
    }
  }

  Future<void> _fetchUserData() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      print('Current user: ${user?.id}');
      if (user == null) {
        print('No authenticated user found');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.pleaseLogIn,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      final response =
          await Supabase.instance.client
              .from('mothers')
              .select('full_name, profile_url')
              .eq('user_id', user.id)
              .maybeSingle();
      print('Mothers response: $response');
      if (response == null) {
        print('No mother record found for user_id: ${user.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.errorFetchingUserData('No user profile found'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onError,
              ),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
        setState(() {
          motherId = user.id;
          fullName = 'Unknown';
          _isLoading = false;
        });
        return;
      }
      setState(() {
        motherId = user.id;
        fullName = response['full_name']?.toString() ?? 'Unknown';
        profileUrl = response['profile_url'] as String?;
        _isLoading = false;
        print('Fetched user data: motherId=$motherId, fullName=$fullName');
      });
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorFetchingUserData(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final size = await file.length();
        if (size > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.imageSizeError,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onError,
                ),
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          return;
        }
        setState(() => _imageFile = file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorPickingImage(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final postProvider = Provider.of<PostProvider>(context, listen: false);

    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _titleController.text.trim().isEmpty
                ? l10n.emptyTitleError
                : l10n.emptyContentError,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    if (motherId == null || fullName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.userDataNotLoaded,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);
      if (widget.post == null) {
        await postProvider.createPost(
          motherId!,
          fullName!,
          _titleController.text.trim(),
          _contentController.text.trim(),
          imageFile: _imageFile,
        );
      } else {
        await postProvider.updatePost(
          widget.post!.id,
          _titleController.text.trim(),
          _contentController.text.trim(),
          imageFile: _imageFile,
        );
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.errorSavingPost(e.toString()),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onError,
            ),
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  ImageProvider? _getImageProvider(String? base64Image) {
    if (base64Image == null || base64Image.isEmpty) return null;
    try {
      final bytes = base64Decode(base64Image);
      return MemoryImage(bytes);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final l10n = AppLocalizations.of(context)!;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder:
          (_, controller) => Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child:
                _isLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    )
                    : Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainer,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: theme.colorScheme.onSurface,
                                ),
                                onPressed: () => Navigator.pop(context),
                                tooltip: l10n.closeTooltip,
                              ),
                              Text(
                                widget.post == null
                                    ? l10n.createPostTitle
                                    : l10n.editPostTitle,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              TextButton(
                                onPressed: _isLoading ? null : _submit,
                                child: Text(
                                  widget.post == null
                                      ? l10n.postButton
                                      : l10n.updateButton,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView(
                            controller: controller,
                            padding: EdgeInsets.all(screenHeight * 0.02),
                            children: [
                              Row(
                                children: [
                                  Semantics(
                                    label: l10n.userAvatar(
                                      fullName ?? 'Unknown',
                                    ),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          theme.colorScheme.secondary,
                                      foregroundColor:
                                          theme.colorScheme.onSecondary,
                                      backgroundImage: _getImageProvider(
                                        profileUrl,
                                      ),
                                      child:
                                          profileUrl == null ||
                                                  _getImageProvider(
                                                        profileUrl,
                                                      ) ==
                                                      null
                                              ? Text(
                                                fullName?.isNotEmpty == true
                                                    ? fullName![0].toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color:
                                                      theme
                                                          .colorScheme
                                                          .onSecondary,
                                                ),
                                              )
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    fullName ?? 'Unknown',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _titleController,
                                decoration: InputDecoration(
                                  hintText: l10n.postTitleHint,
                                  hintStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                  border: InputBorder.none,
                                ),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _contentController,
                                decoration: InputDecoration(
                                  hintText: l10n.whatsOnYourMind,
                                  hintStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                  border: InputBorder.none,
                                ),
                                maxLines: null,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_imageFile != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _imageFile!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.cancel,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _imageFile = null,
                                            ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: theme
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                        tooltip: l10n.removeImageTooltip,
                                      ),
                                    ),
                                  ],
                                )
                              else if (widget.post?.imageUrl != null)
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        widget.post!.imageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (_, __, ___) => Icon(
                                              Icons.broken_image,
                                              color:
                                                  theme
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.cancel,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                        onPressed:
                                            () => setState(
                                              () => _imageFile = null,
                                            ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: theme
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                        ),
                                        tooltip: l10n.removeImageTooltip,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.image,
                                      color: theme.colorScheme.secondary,
                                    ),
                                    onPressed: _pickImage,
                                    tooltip: l10n.addImageTooltip,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
          ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
