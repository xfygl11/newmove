import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/providers.dart';
import '../../data/app_database.dart';
import 'novel_providers.dart';

/// 阅读器主题类型。
enum ReaderTheme { dark, light, sepia }

/// 阅读器主题配置。
class _ReaderThemeConfig {
  const _ReaderThemeConfig({
    required this.backgroundColor,
    required this.textStyle,
    required this.titleStyle,
  });

  final Color backgroundColor;
  final TextStyle textStyle;
  final TextStyle titleStyle;

  static const _dark = _ReaderThemeConfig(
    backgroundColor: Colors.black87,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 16,
      height: 1.8,
    ),
    titleStyle: TextStyle(
      color: Colors.white70,
      fontSize: 14,
    ),
  );

  static const _light = _ReaderThemeConfig(
    backgroundColor: Colors.white,
    textStyle: TextStyle(
      color: Colors.black87,
      fontSize: 16,
      height: 1.8,
    ),
    titleStyle: TextStyle(
      color: Colors.grey,
      fontSize: 14,
    ),
  );

  static const _sepia = _ReaderThemeConfig(
    backgroundColor: Color(0xFFF5F0E1),
    textStyle: TextStyle(
      color: Color(0xFF3E3428),
      fontSize: 16,
      height: 1.8,
    ),
    titleStyle: TextStyle(
      color: Color(0xFF8B7355),
      fontSize: 14,
    ),
  );

  static _ReaderThemeConfig of(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return _dark;
      case ReaderTheme.light:
        return _light;
      case ReaderTheme.sepia:
        return _sepia;
    }
  }
}

/// 阅读器页面：按章节翻页阅读小说，支持进度记忆、字号调整、目录、主题切换。
class ReaderPage extends ConsumerStatefulWidget {
  const ReaderPage({super.key, required this.bookId});

  final int bookId;

  @override
  ConsumerState<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends ConsumerState<ReaderPage> {
  int _currentIndex = 0;
  double _fontSize = 16;
  ReaderTheme _theme = ReaderTheme.dark;
  Timer? _saveProgressTimer;
  int _chapterWordCount = 0;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  @override
  void dispose() {
    _saveProgressTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreProgress() async {
    final progressDao = ref.read(readingProgressDaoProvider);
    final progress = await progressDao.findByBook(widget.bookId);
    if (progress != null && mounted) {
      setState(() {
        _currentIndex = progress.chapterSeq - 1;
      });
    }
  }

  void _saveProgress(int chapterSeq) {
    _saveProgressTimer?.cancel();
    _saveProgressTimer = Timer(const Duration(seconds: 2), () async {
      final progressDao = ref.read(readingProgressDaoProvider);
      final chaptersAsync = ref.read(chaptersByBookProvider(widget.bookId));
      final chapters = chaptersAsync.value ?? [];
      if (_currentIndex >= 0 && _currentIndex < chapters.length) {
        final chapter = chapters[_currentIndex];
        await progressDao.save(
          widget.bookId,
          chapter.seq,
          chapter.id,
        );
      }
    });
  }

  void _showTocSheet(List<Chapter> chapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: _ReaderThemeConfig.of(_theme).backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Expanded(child: Text('目录')),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = chapters[index];
                    final isSelected = index == _currentIndex;
                    return ListTile(
                      title: Text(
                        '第${chapter.seq}章 ${chapter.title}'.trim(),
                        style: TextStyle(
                          color: _ReaderThemeConfig.of(_theme).textStyle.color,
                          fontSize: 15,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      onTap: () {
                        setState(() => _currentIndex = index);
                        _saveProgress(chapter.seq);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFontSizeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fontSize = (_fontSize - 2).clamp(12.0, 28.0);
                      });
                    },
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '${_fontSize.toInt()}px',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fontSize = (_fontSize + 2).clamp(12.0, 28.0);
                      });
                    },
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('完成'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final theme in ReaderTheme.values)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _theme = theme);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            width: 60,
                            height: 60,
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: _ReaderThemeConfig.of(theme).backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme == _theme
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                _themeLabel(theme),
                                style: TextStyle(
                                  color: _ReaderThemeConfig.of(theme)
                                      .textStyle
                                      .color,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(_themeLabel(theme)),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _themeLabel(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return '暗色';
      case ReaderTheme.light:
        return '亮色';
      case ReaderTheme.sepia:
        return '护眼';
    }
  }

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(chaptersByBookProvider(widget.bookId));
    final bookAsync = ref.watch(
      StreamProvider<NovelBook?>(
        (ref) => ref.watch(novelDaoProvider).watchBookById(widget.bookId),
      ),
    );

    final themeConfig = _ReaderThemeConfig.of(_theme);

    return Scaffold(
      backgroundColor: themeConfig.backgroundColor,
      appBar: AppBar(
        backgroundColor: themeConfig.backgroundColor,
        foregroundColor: themeConfig.textStyle.color,
        title: Text(
          bookAsync.value?.title ?? '阅读器',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: themeConfig.titleStyle,
        ),
        actions: [
          IconButton(
            tooltip: '目录',
            onPressed: () {
              final chapters = chaptersAsync.value ?? [];
              if (chapters.isNotEmpty) {
                _showTocSheet(chapters);
              }
            },
            icon: Icon(
              Icons.list,
              color: themeConfig.textStyle.color,
            ),
          ),
          IconButton(
            tooltip: '上一章',
            onPressed: _currentIndex > 0
                ? () {
                    setState(() => _currentIndex--);
                    _saveProgress(_currentIndex + 1);
                  }
                : null,
            icon: Icon(
              Icons.chevron_left,
              color: themeConfig.textStyle.color,
            ),
          ),
          IconButton(
            tooltip: '下一章',
            onPressed: () {
              final chapters = chaptersAsync.value ?? [];
              if (_currentIndex < chapters.length - 1) {
                setState(() => _currentIndex++);
                _saveProgress(_currentIndex + 1);
              }
            },
            icon: Icon(
              Icons.chevron_right,
              color: themeConfig.textStyle.color,
            ),
          ),
        ],
      ),
      body: chaptersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('加载失败：$e', style: themeConfig.textStyle),
        ),
        data: (chapters) {
          if (chapters.isEmpty) {
            return Center(
              child: Text('还没有章节', style: themeConfig.textStyle),
            );
          }

          if (_currentIndex >= chapters.length) {
            _currentIndex = chapters.length - 1;
          }

          final chapter = chapters[_currentIndex];
          _chapterWordCount = chapter.content?.length ?? 0;
          final progressPercent = (_currentIndex + 1) / chapters.length;

          return Column(
            children: [
              LinearProgressIndicator(
                value: progressPercent,
                minHeight: 2,
                backgroundColor: Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '第${chapter.seq}章 ${chapter.title}'.trim(),
                        style: themeConfig.titleStyle,
                      ),
                    ),
                    Text(
                      '${_currentIndex + 1} / ${chapters.length}',
                      style: themeConfig.titleStyle,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_chapterWordCount}字',
                      style: themeConfig.titleStyle,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '${_fontSize.toInt()}px',
                      style: themeConfig.titleStyle,
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: chapter.content != null && chapter.content!.isNotEmpty
                    ? SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          chapter.content!,
                          style: themeConfig.textStyle.copyWith(
                            fontSize: _fontSize,
                          ),
                        ),
                      )
                    : Center(
                        child: Text('本章暂无正文', style: themeConfig.textStyle),
                      ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: themeConfig.backgroundColor.withValues(alpha: 0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      tooltip: '字号调整',
                      onPressed: _showFontSizeSheet,
                      icon: Icon(
                        Icons.format_size,
                        color: themeConfig.textStyle.color,
                      ),
                    ),
                    IconButton(
                      tooltip: '切换主题',
                      onPressed: _showThemeSheet,
                      icon: Icon(
                        Icons.palette,
                        color: themeConfig.textStyle.color,
                      ),
                    ),
                    IconButton(
                      tooltip: '目录',
                      onPressed: () {
                        final chapters = chaptersAsync.value ?? [];
                        if (chapters.isNotEmpty) {
                          _showTocSheet(chapters);
                        }
                      },
                      icon: Icon(
                        Icons.list,
                        color: themeConfig.textStyle.color,
                      ),
                    ),
                    IconButton(
                      tooltip: '上一章',
                      onPressed: _currentIndex > 0
                          ? () {
                              setState(() => _currentIndex--);
                              _saveProgress(_currentIndex + 1);
                            }
                          : null,
                      icon: Icon(
                        Icons.chevron_left,
                        color: themeConfig.textStyle.color,
                      ),
                    ),
                    IconButton(
                      tooltip: '下一章',
                      onPressed: () {
                        final chapters = chaptersAsync.value ?? [];
                        if (_currentIndex < chapters.length - 1) {
                          setState(() => _currentIndex++);
                          _saveProgress(_currentIndex + 1);
                        }
                      },
                      icon: Icon(
                        Icons.chevron_right,
                        color: themeConfig.textStyle.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
