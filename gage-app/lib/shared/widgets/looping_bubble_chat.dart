import 'dart:async';
import 'package:flutter/material.dart';

class LoopingBubbleChat extends StatefulWidget {
  final List<String> messages;
  final String senderName;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final String? actionLabel;
  final VoidCallback onTap;

  const LoopingBubbleChat({
    super.key,
    required this.messages,
    required this.senderName,
    this.subtitle,
    required this.icon,
    this.primaryColor = const Color(0xFF00880C),
    this.backgroundColor = Colors.white,
    this.actionLabel,
    required this.onTap,
  });

  @override
  State<LoopingBubbleChat> createState() => _LoopingBubbleChatState();
}

class _LoopingBubbleChatState extends State<LoopingBubbleChat>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isTyping = true;
  Timer? _loopTimer;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _startAnimationCycle();
  }

  void _startAnimationCycle() {
    _loopTimer?.cancel();
    if (!mounted) return;

    // Phase 1: Typing for 1.4 seconds
    setState(() => _isTyping = true);

    _loopTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      // Phase 2: Show message for 4.2 seconds
      setState(() => _isTyping = false);

      _loopTimer = Timer(const Duration(milliseconds: 4200), () {
        if (!mounted) return;

        // Advance to next message
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.messages.length;
        });

        // Loop again
        _startAnimationCycle();
      });
    });
  }

  @override
  void dispose() {
    _loopTimer?.cancel();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentMessage = widget.messages.isNotEmpty
        ? widget.messages[_currentIndex]
        : '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Icon with pulsing ring
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.primaryColor,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Chat Bubble Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.senderName,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '• ${widget.subtitle}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.2),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: _isTyping
                          ? _buildTypingIndicator()
                          : Text(
                              currentMessage,
                              key: ValueKey<int>(_currentIndex),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action Arrow or Button
              if (widget.actionLabel != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.actionLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                    ],
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.primaryColor.withValues(alpha: 0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      key: const ValueKey<String>('typing_dots'),
      animation: _dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mengetik',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 5),
            ...List.generate(3, (i) {
              final val = (_dotsController.value - (i * 0.2)) % 1.0;
              final bounce = (val >= 0 && val <= 0.5)
                  ? (1.0 - (val - 0.25).abs() * 4)
                  : 0.0;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 4.5,
                height: 4.5 + (bounce * 3),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withValues(
                    alpha: 0.4 + (bounce * 0.6),
                  ),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
