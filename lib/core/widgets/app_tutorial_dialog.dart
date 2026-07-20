import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

@immutable
class AppTutorialPage {
  const AppTutorialPage({
    required this.title,
    required this.description,
    required this.imageAsset,
  });

  final String title;
  final String description;
  final String imageAsset;
}

class AppTutorialDialog extends StatefulWidget {
  const AppTutorialDialog({
    super.key,
    required this.heading,
    required this.pages,
    this.completionLabel = 'はじめる',
  });

  final String heading;
  final List<AppTutorialPage> pages;
  final String completionLabel;

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  static const _pageAnimationDuration = Duration(milliseconds: 280);

  final PageController _controller = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  bool get _isLastPage => _currentPage == widget.pages.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int index) async {
    if (_isAnimating ||
        index < 0 ||
        index >= widget.pages.length ||
        index == _currentPage) {
      return;
    }

    _isAnimating = true;
    try {
      await _controller.animateToPage(
        index,
        duration: _pageAnimationDuration,
        curve: Curves.easeOutCubic,
      );
    } finally {
      _isAnimating = false;
    }
  }

  void _advanceFromTap() {
    if (!_isLastPage) {
      _goToPage(_currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxHeight < 620;
          return SizedBox(
            width: 380,
            height: 720,
            child: ClipRect(
              child: Column(
                children: [
                  _TutorialHeader(
                    heading: widget.heading,
                    compact: compact,
                    onSkip: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: PageView.builder(
                      key: const ValueKey('tutorial-page-view'),
                      controller: _controller,
                      itemCount: widget.pages.length,
                      physics: const PageScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemBuilder: (context, index) {
                        return _TutorialPageBody(
                          page: widget.pages[index],
                          index: index,
                          compact: compact,
                          isLastPage: index == widget.pages.length - 1,
                          completionLabel: widget.completionLabel,
                          onTap: _advanceFromTap,
                          onComplete: () => Navigator.of(context).pop(),
                        );
                      },
                    ),
                  ),
                  _TutorialIndicators(
                    pageCount: widget.pages.length,
                    currentPage: _currentPage,
                    compact: compact,
                    onSelected: _goToPage,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TutorialHeader extends StatelessWidget {
  const _TutorialHeader({
    required this.heading,
    required this.compact,
    required this.onSkip,
  });

  final String heading;
  final bool compact;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 54 : 68,
      padding: EdgeInsets.fromLTRB(24, compact ? 6 : 12, 16, 0),
      decoration: const BoxDecoration(gradient: _tutorialGradient),
      child: Row(
        children: [
          Expanded(
            child: Text(
              heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            key: const ValueKey('tutorial-skip'),
            onPressed: onSkip,
            child: const Text(
              'スキップ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialPageBody extends StatelessWidget {
  const _TutorialPageBody({
    required this.page,
    required this.index,
    required this.compact,
    required this.isLastPage,
    required this.completionLabel,
    required this.onTap,
    required this.onComplete,
  });

  final AppTutorialPage page;
  final int index;
  final bool compact;
  final bool isLastPage;
  final String completionLabel;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('tutorial-page-$index'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            flex: compact ? 44 : 58,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(gradient: _tutorialGradient),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 20 : 28,
                vertical: compact ? 8 : 12,
              ),
              child: RepaintBoundary(
                key: ValueKey('tutorial-image-$index'),
                child: SvgPicture.asset(
                  page.imageAsset,
                  fit: BoxFit.contain,
                  semanticsLabel: page.title,
                ),
              ),
            ),
          ),
          Expanded(
            flex: compact ? 56 : 42,
            child: Container(
              key: ValueKey('tutorial-description-$index'),
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.fromLTRB(
                compact ? 22 : 34,
                compact ? 12 : 20,
                compact ? 22 : 34,
                compact ? 10 : 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    page.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 17 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: compact ? 6 : 12),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Text(
                        page.description,
                        style: TextStyle(
                          fontSize: compact ? 13 : 16,
                          height: compact ? 1.4 : 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (isLastPage) ...[
                    SizedBox(height: compact ? 6 : 10),
                    SizedBox(
                      width: double.infinity,
                      height: compact ? 42 : 48,
                      child: ElevatedButton(
                        key: const ValueKey('tutorial-complete'),
                        onPressed: onComplete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          completionLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialIndicators extends StatelessWidget {
  const _TutorialIndicators({
    required this.pageCount,
    required this.currentPage,
    required this.compact,
    required this.onSelected,
  });

  final int pageCount;
  final int currentPage;
  final bool compact;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 48 : 64,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(pageCount, (index) {
          final selected = currentPage == index;
          return Semantics(
            button: true,
            selected: selected,
            label: '${index + 1}ページ目へ移動',
            child: GestureDetector(
              key: ValueKey('tutorial-indicator-$index'),
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: SizedBox.square(
                dimension: 44,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: selected ? Colors.blue : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

const _tutorialGradient = LinearGradient(
  colors: [Color(0xff2F80ED), Color(0xff2563EB)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);
