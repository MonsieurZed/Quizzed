import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:quizzed/models/question.dart';
import 'package:quizzed/models/quiz_session.dart';
import 'package:quizzed/repositories/quiz_repository.dart';
import 'package:quizzed/services/storage_service.dart';
import 'package:quizzed/services/logging_service.dart';
import 'package:file_picker/file_picker.dart';

class QuizCreationScreen extends StatefulWidget {
  final String? sessionId;

  const QuizCreationScreen({super.key, this.sessionId});

  @override
  State<QuizCreationScreen> createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends State<QuizCreationScreen> {
  final QuizRepository _quizRepository = QuizRepository();
  final StorageService _storageService = StorageService();
  final LoggingService _logger = LoggingService();
  final _sessionFormKey = GlobalKey<FormState>();
  final _questionFormKey = GlobalKey<FormState>();

  // Session data
  final _sessionTitleController = TextEditingController();
  final _sessionDescriptionController = TextEditingController();
  final _validationThresholdController = TextEditingController(text: '50');

  String? _sessionId;
  bool _isSessionCreated = false;
  bool _isLoading = false;

  // Question data
  final _questionTextController = TextEditingController();
  QuestionType _selectedType = QuestionType.qcm;
  QuestionDifficulty _selectedDifficulty = QuestionDifficulty.medium;
  final _choicesController = TextEditingController();
  final _correctAnswerController = TextEditingController();
  final _pointsController = TextEditingController(text: '10');
  final _timeLimitController = TextEditingController(text: '30');
  int _questionOrder = 1;

  List<Question> _questions = [];
  String? _mediaPath;
  Uint8List? _mediaBytes;
  String? _mediaUrl;
  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _logger.logInfo(
      'Quiz creation screen initialized' +
          (widget.sessionId != null
              ? ' for editing session: ${widget.sessionId}'
              : ''),
      'QuizCreationScreen.initState',
    );

    if (widget.sessionId != null) {
      _sessionId = widget.sessionId;
      _isSessionCreated = true;
      _loadExistingSession();
      _loadExistingQuestions();
    }
  }

  @override
  void dispose() {
    _logger.logInfo(
      'Quiz creation screen disposed',
      'QuizCreationScreen.dispose',
    );
    _sessionTitleController.dispose();
    _sessionDescriptionController.dispose();
    _validationThresholdController.dispose();
    _questionTextController.dispose();
    _choicesController.dispose();
    _correctAnswerController.dispose();
    _pointsController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingSession() async {
    setState(() => _isLoading = true);

    try {
      _logger.logInfo(
        'Loading existing session: $_sessionId',
        'QuizCreationScreen._loadExistingSession',
      );

      final sessionStream = _quizRepository.getQuizSession(_sessionId!);
      final sessionData = await sessionStream.first;

      if (sessionData != null) {
        setState(() {
          _sessionTitleController.text = sessionData.title;
          _sessionDescriptionController.text = sessionData.description ?? '';
          _validationThresholdController.text =
              sessionData.validationThreshold.toString();
        });

        _logger.logInfo(
          'Existing session loaded: "${sessionData.title}"',
          'QuizCreationScreen._loadExistingSession',
        );
      } else {
        _logger.logWarning(
          'Session not found: $_sessionId',
          'QuizCreationScreen._loadExistingSession',
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        'Error loading session: $_sessionId',
        e,
        stackTrace,
        'QuizCreationScreen._loadExistingSession',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading session: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadExistingQuestions() async {
    setState(() => _isLoading = true);

    try {
      _logger.logInfo(
        'Loading questions for session: $_sessionId',
        'QuizCreationScreen._loadExistingQuestions',
      );

      final questionsStream = _quizRepository.getSessionQuestions(_sessionId!);
      final questionsData = await questionsStream.first;

      if (questionsData.isNotEmpty) {
        setState(() {
          _questions = questionsData;
          _questionOrder =
              questionsData
                  .map((q) => q.order)
                  .fold(0, (max, order) => order > max ? order : max) +
              1;
        });

        _logger.logInfo(
          'Loaded ${questionsData.length} questions for session: $_sessionId',
          'QuizCreationScreen._loadExistingQuestions',
        );
      } else {
        _logger.logInfo(
          'No questions found for session: $_sessionId',
          'QuizCreationScreen._loadExistingQuestions',
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        'Error loading questions for session: $_sessionId',
        e,
        stackTrace,
        'QuizCreationScreen._loadExistingQuestions',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading questions: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createSession() async {
    if (!_sessionFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final sessionTitle = _sessionTitleController.text.trim();

      _logger.logInfo(
        'Creating new quiz session: "$sessionTitle"',
        'QuizCreationScreen._createSession',
      );

      final session = QuizSession(
        title: sessionTitle,
        description: _sessionDescriptionController.text.trim(),
        createdAt: DateTime.now(),
        isActive: false,
        validationThreshold: int.parse(_validationThresholdController.text),
      );

      final sessionId = await _quizRepository.createQuizSession(session);

      setState(() {
        _sessionId = sessionId;
        _isSessionCreated = true;
      });

      _logger.logInfo(
        'Quiz session created successfully with ID: $sessionId',
        'QuizCreationScreen._createSession',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session created successfully')),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error creating session',
        e,
        stackTrace,
        'QuizCreationScreen._createSession',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating session: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSession() async {
    if (!_sessionFormKey.currentState!.validate() || _sessionId == null) return;

    setState(() => _isLoading = true);

    try {
      final sessionTitle = _sessionTitleController.text.trim();

      _logger.logInfo(
        'Updating quiz session: "$sessionTitle" (ID: $_sessionId)',
        'QuizCreationScreen._updateSession',
      );

      final session = QuizSession(
        id: _sessionId,
        title: sessionTitle,
        description: _sessionDescriptionController.text.trim(),
        createdAt: DateTime.now(),
        isActive: false,
        validationThreshold: int.parse(_validationThresholdController.text),
      );

      await _quizRepository.updateQuizSession(_sessionId!, session);

      _logger.logInfo(
        'Quiz session updated successfully: "$sessionTitle" (ID: $_sessionId)',
        'QuizCreationScreen._updateSession',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session updated successfully')),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error updating session: $_sessionId',
        e,
        stackTrace,
        'QuizCreationScreen._updateSession',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error updating session: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMedia() async {
    try {
      _logger.logInfo(
        'Picking media file for question type: ${_getQuestionTypeLabel(_selectedType)}',
        'QuizCreationScreen._pickMedia',
      );

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: _getFileType(),
        allowCompression: true,
        withData: true, // Always get the bytes for cross-platform compatibility
      );

      if (result != null && result.files.isNotEmpty) {
        final fileName = result.files.single.name;

        setState(() {
          // For web, the path won't be available, but bytes will be
          if (kIsWeb) {
            _mediaPath = fileName; // Just store the filename for display
            _mediaBytes = result.files.single.bytes;
          } else {
            _mediaPath = result.files.single.path;
          }
        });

        _logger.logInfo(
          'Media file selected: $fileName',
          'QuizCreationScreen._pickMedia',
        );
      } else {
        _logger.logInfo(
          'No media file selected',
          'QuizCreationScreen._pickMedia',
        );
      }
    } catch (e, stackTrace) {
      _logger.logError(
        'Error picking file',
        e,
        stackTrace,
        'QuizCreationScreen._pickMedia',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  FileType _getFileType() {
    switch (_selectedType) {
      case QuestionType.image:
        return FileType.image;
      case QuestionType.sound:
        return FileType.audio;
      case QuestionType.video:
        return FileType.video;
      default:
        return FileType.any;
    }
  }

  Future<void> _uploadMedia() async {
    if (_mediaPath == null && _mediaBytes == null) return;

    setState(() => _isUploadingMedia = true);

    try {
      _logger.logInfo(
        'Uploading media file: ${_mediaPath ?? "bytes data"}',
        'QuizCreationScreen._uploadMedia',
      );

      // Using the temporary session ID or actual ID if available
      String tempSessionId =
          _sessionId ?? 'temp_${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb && _mediaBytes != null) {
        String fileExtension = _getFileExtension();
        String mediaType = _getMediaType();
        _mediaUrl = await _storageService.uploadBytes(
          _mediaBytes!,
          mediaType,
          tempSessionId,
          fileExtension,
        );
      } else if (!kIsWeb && _mediaPath != null) {
        File file = File(_mediaPath!);

        switch (_selectedType) {
          case QuestionType.image:
            _mediaUrl = await _storageService.uploadImage(file, tempSessionId);
            break;
          case QuestionType.sound:
            _mediaUrl = await _storageService.uploadAudio(file, tempSessionId);
            break;
          case QuestionType.video:
            _mediaUrl = await _storageService.uploadVideo(file, tempSessionId);
            break;
          default:
            _mediaUrl = null;
        }
      }

      _logger.logInfo(
        'Media file uploaded successfully, URL: $_mediaUrl',
        'QuizCreationScreen._uploadMedia',
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error uploading media file',
        e,
        stackTrace,
        'QuizCreationScreen._uploadMedia',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading file: $e')));
    } finally {
      setState(() => _isUploadingMedia = false);
    }
  }

  String _getMediaType() {
    switch (_selectedType) {
      case QuestionType.image:
        return 'image';
      case QuestionType.sound:
        return 'audio';
      case QuestionType.video:
        return 'video';
      default:
        return 'image';
    }
  }

  String _getFileExtension() {
    if (_mediaPath != null) {
      return _mediaPath!.substring(_mediaPath!.lastIndexOf('.'));
    }

    // Default extensions based on media type
    switch (_selectedType) {
      case QuestionType.image:
        return '.jpg';
      case QuestionType.sound:
        return '.mp3';
      case QuestionType.video:
        return '.mp4';
      default:
        return '.bin';
    }
  }

  Future<void> _addQuestion() async {
    if (!_questionFormKey.currentState!.validate() || _sessionId == null)
      return;

    // Upload media if selected
    if (_mediaPath != null && _mediaUrl == null) {
      await _uploadMedia();
    }

    setState(() => _isLoading = true);

    try {
      final questionText = _questionTextController.text.trim();
      _logger.logInfo(
        'Adding question to session $_sessionId: "$questionText" (Type: ${_getQuestionTypeLabel(_selectedType)})',
        'QuizCreationScreen._addQuestion',
      );

      // Parse choices for QCM questions
      List<String>? choices;
      dynamic correctAnswer;

      if (_selectedType == QuestionType.qcm) {
        choices =
            _choicesController.text
                .split('\n')
                .map((c) => c.trim())
                .where((c) => c.isNotEmpty)
                .toList();

        // Make sure we have at least 2 choices
        if (choices.length < 2) {
          _logger.logWarning(
            'Not enough choices: ${choices.length} (minimum 2 required)',
            'QuizCreationScreen._addQuestion',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please add at least 2 choices')),
          );
          setState(() => _isLoading = false);
          return;
        }

        // Parse correct answer (could be a single index or comma-separated indices)
        try {
          if (_correctAnswerController.text.contains(',')) {
            List<int> indices =
                _correctAnswerController.text
                    .split(',')
                    .map((s) => int.parse(s.trim()))
                    .toList();
            correctAnswer = indices;
          } else {
            correctAnswer = int.parse(_correctAnswerController.text.trim());
          }
        } catch (e) {
          _logger.logWarning(
            'Invalid correct answer format: ${_correctAnswerController.text}',
            'QuizCreationScreen._addQuestion',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid correct answer format')),
          );
          setState(() => _isLoading = false);
          return;
        }
      } else if (_selectedType == QuestionType.open) {
        // For open questions, just store the correct answer as a string
        correctAnswer = _correctAnswerController.text.trim();
      }

      final question = Question(
        sessionId: _sessionId!,
        questionText: questionText,
        type: _selectedType,
        mediaUrl: _mediaUrl,
        choices: choices,
        correctAnswer: correctAnswer,
        order: _questionOrder,
        difficulty: _selectedDifficulty,
        points: int.parse(_pointsController.text),
        timeLimit: int.parse(_timeLimitController.text),
      );

      await _quizRepository.createQuestion(question);

      _logger.logInfo(
        'Question added successfully to session $_sessionId (order: $_questionOrder)',
        'QuizCreationScreen._addQuestion',
      );

      // Add the question to the local list and update the order for the next question
      setState(() {
        _questions.add(question);
        _questionOrder++;

        // Reset form fields for next question
        _questionTextController.clear();
        _choicesController.clear();
        _correctAnswerController.clear();
        _pointsController.text = '10';
        _timeLimitController.text = '30';
        _mediaPath = null;
        _mediaUrl = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question added successfully')),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error adding question to session $_sessionId',
        e,
        stackTrace,
        'QuizCreationScreen._addQuestion',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding question: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteQuestion(String questionId) async {
    setState(() => _isLoading = true);

    try {
      _logger.logInfo(
        'Deleting question: $questionId from session $_sessionId',
        'QuizCreationScreen._deleteQuestion',
      );

      await _quizRepository.deleteQuestion(questionId);

      setState(() {
        _questions.removeWhere((q) => q.id == questionId);
      });

      _logger.logInfo(
        'Question deleted successfully: $questionId',
        'QuizCreationScreen._deleteQuestion',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Question deleted successfully')),
      );
    } catch (e, stackTrace) {
      _logger.logError(
        'Error deleting question: $questionId',
        e,
        stackTrace,
        'QuizCreationScreen._deleteQuestion',
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting question: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Détection du format PC large
    final screenSize = MediaQuery.of(context).size;
    final ratio = screenSize.width / screenSize.height;
    final isDesktop = ratio >= 1.6 && screenSize.width > 1200;

    // Get theme colors
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar:
          isDesktop
              ? null
              : AppBar(
                title: Text(
                  _isSessionCreated
                      ? 'Edit Quiz Session'
                      : 'Create Quiz Session',
                ),
                actions: [
                  if (_isSessionCreated)
                    IconButton(
                      icon: const Icon(Icons.save),
                      onPressed: _updateSession,
                      tooltip: 'Save Session',
                    ),
                ],
              ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(color: colorScheme.primary),
              )
              : isDesktop
              ? Row(
                children: [
                  // Panneau latéral : infos session + liste des questions
                  Container(
                    width: 420,
                    color: colorScheme.surfaceVariant,
                    child: Column(
                      children: [
                        // Header infos session
                        Container(
                          height: 70,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.shadow.withOpacity(0.05),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Session',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Formulaire infos session
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _buildSessionForm(),
                        ),
                        // Header liste questions
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Icon(Icons.list_alt, color: colorScheme.primary),
                              const SizedBox(width: 12),
                              Text(
                                'Questions',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              Chip(
                                label: Text('${_questions.length}'),
                                backgroundColor: colorScheme.primaryContainer,
                              ),
                            ],
                          ),
                        ),
                        // Liste des questions
                        Expanded(
                          child:
                              _questions.isEmpty
                                  ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 30,
                                      ),
                                      child: Text(
                                        'Aucune question ajoutée',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  )
                                  : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _questions.length,
                                    itemBuilder: (context, index) {
                                      final question = _questions[index];
                                      return Card(
                                        elevation: 0,
                                        margin: const EdgeInsets.only(
                                          bottom: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: colorScheme.outlineVariant,
                                            width: 1,
                                          ),
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                colorScheme.primaryContainer,
                                            foregroundColor:
                                                colorScheme.onPrimaryContainer,
                                            child: Text((index + 1).toString()),
                                          ),
                                          title: Text(
                                            question.questionText,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          subtitle: Text(
                                            '${_getQuestionTypeLabel(question.type)} | ${_getQuestionDifficultyLabel(question.difficulty)} | ${question.points} pts',
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              Icons.delete,
                                              color: colorScheme.error,
                                            ),
                                            onPressed:
                                                () => _deleteQuestion(
                                                  question.id!,
                                                ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                        ),
                      ],
                    ),
                  ),
                  // Panneau principal : formulaire question
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 32,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header moderne
                          Row(
                            children: [
                              Icon(
                                _isSessionCreated
                                    ? Icons.edit
                                    : Icons.add_circle,
                                color: colorScheme.primary,
                                size: 32,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                _isSessionCreated
                                    ? 'Édition de la session'
                                    : 'Création d\'une session',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              if (_isSessionCreated)
                                ElevatedButton.icon(
                                  onPressed: _updateSession,
                                  icon: const Icon(Icons.save),
                                  label: const Text('Enregistrer'),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          if (_isSessionCreated) ...[_buildQuestionForm()],
                        ],
                      ),
                    ),
                  ),
                ],
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSessionForm(),
                    const SizedBox(height: 32),
                    if (_isSessionCreated) _buildQuestionForm(),
                    const SizedBox(height: 32),
                    if (_isSessionCreated) _buildQuestionsList(),
                  ],
                ),
              ),
    );
  }

  Widget _buildSessionForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _sessionTitleController,
              decoration: const InputDecoration(
                labelText: 'Session Name',
                hintText: 'Enter a name for this session',
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _sessionDescriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            if (!_isSessionCreated)
              ElevatedButton.icon(
                onPressed: _createSession,
                icon: const Icon(Icons.check),
                label: const Text('Create Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionForm() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _questionFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Add Question',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _questionTextController,
                decoration: InputDecoration(
                  labelText: 'Question Text',
                  hintText: 'Enter your question here',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<QuestionType>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: QuestionType.qcm,
                          child: Text('Multiple Choice'),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.open,
                          child: Text('Open'),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.image,
                          child: Text('Image'),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.sound,
                          child: Text('Sound'),
                        ),
                        DropdownMenuItem(
                          value: QuestionType.video,
                          child: Text('Video'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                          // Reset media when changing types
                          _mediaPath = null;
                          _mediaBytes = null;
                          _mediaUrl = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<QuestionDifficulty>(
                      value: _selectedDifficulty,
                      decoration: InputDecoration(
                        labelText: 'Difficulty',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: QuestionDifficulty.easy,
                          child: Text('Easy'),
                        ),
                        DropdownMenuItem(
                          value: QuestionDifficulty.medium,
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: QuestionDifficulty.hard,
                          child: Text('Hard'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedDifficulty = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      decoration: InputDecoration(
                        labelText: 'Points',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Enter a number';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Time limit
              TextFormField(
                controller: _timeLimitController,
                decoration: InputDecoration(
                  labelText: 'Time Limit (seconds)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Enter a number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Media upload for image, sound, and video questions
              if (_selectedType == QuestionType.image ||
                  _selectedType == QuestionType.sound ||
                  _selectedType == QuestionType.video)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: colorScheme.tertiaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _selectedType == QuestionType.image
                                  ? Icons.image
                                  : _selectedType == QuestionType.sound
                                  ? Icons.audio_file
                                  : Icons.video_file,
                              color: colorScheme.onTertiaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_getQuestionTypeLabel(_selectedType)} Upload',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_mediaPath != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colorScheme.outline),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _selectedType == QuestionType.image
                                      ? Icons.image
                                      : _selectedType == QuestionType.sound
                                      ? Icons.audio_file
                                      : Icons.video_file,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _mediaPath!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    setState(() {
                                      _mediaPath = null;
                                      _mediaBytes = null;
                                      _mediaUrl = null;
                                    });
                                  },
                                  color: colorScheme.error,
                                ),
                              ],
                            ),
                          ),
                        ElevatedButton.icon(
                          onPressed: _pickMedia,
                          icon: const Icon(Icons.upload_file),
                          label: Text(
                            'Select ${_getQuestionTypeLabel(_selectedType)}',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.tertiary,
                            foregroundColor: colorScheme.onTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Answer options for QCM questions
              if (_selectedType == QuestionType.qcm)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSecondaryContainer,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _choicesController,
                          decoration: InputDecoration(
                            labelText: 'Choices (one per line)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: 'Paris\nLondon\nBerlin\nRome',
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (_selectedType == QuestionType.qcm) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter at least 2 choices';
                              }
                              final choices =
                                  value
                                      .split('\n')
                                      .map((e) => e.trim())
                                      .where((e) => e.isNotEmpty)
                                      .toList();
                              if (choices.length < 2) {
                                return 'Please enter at least 2 choices';
                              }
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _correctAnswerController,
                          decoration: InputDecoration(
                            labelText: 'Correct Answer (index or indices)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            hintText: '0 or 0,2,3',
                            helperText:
                                'Enter the index(es) starting from 0, separated by commas for multiple',
                          ),
                          validator: (value) {
                            if (_selectedType == QuestionType.qcm) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter the correct answer index';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              // Correct answer for open questions
              if (_selectedType == QuestionType.open)
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 0,
                  color: colorScheme.secondaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.edit_note,
                              color: colorScheme.onSecondaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Correct Answer',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _correctAnswerController,
                          decoration: InputDecoration(
                            labelText: 'Expected Answer',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            helperText:
                                'Players will need community validation',
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addQuestion,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Question'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionsList() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Questions List',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_questions.length}'),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_questions.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'No questions added yet',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colorScheme.primaryContainer,
                        foregroundColor: colorScheme.onPrimaryContainer,
                        child: Text('${index + 1}'),
                      ),
                      title: Text(question.questionText),
                      subtitle: Text(
                        '${_getQuestionTypeLabel(question.type)} | ${_getQuestionDifficultyLabel(question.difficulty)} | ${question.points} pts',
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        onPressed: () => _deleteQuestion(question.id!),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Helper method to get readable labels for question types
  String _getQuestionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.qcm:
        return 'Multiple Choice';
      case QuestionType.image:
        return 'Image';
      case QuestionType.sound:
        return 'Sound';
      case QuestionType.video:
        return 'Video';
      case QuestionType.open:
        return 'Open';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get readable labels for difficulty levels
  String _getQuestionDifficultyLabel(QuestionDifficulty difficulty) {
    switch (difficulty) {
      case QuestionDifficulty.easy:
        return 'Easy';
      case QuestionDifficulty.medium:
        return 'Medium';
      case QuestionDifficulty.hard:
        return 'Hard';
      default:
        return 'Medium';
    }
  }
}
