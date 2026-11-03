import 'package:flutter/material.dart';

/// Compact typed-reply fallback for the voice-first screens. Speech input can
/// be denied or unsupported, so typing must always remain possible.
class TypedReplyBar extends StatefulWidget {
  const TypedReplyBar({super.key, required this.onSubmit, this.enabled = true});

  final ValueChanged<String> onSubmit;
  final bool enabled;

  @override
  State<TypedReplyBar> createState() => _TypedReplyBarState();
}

class _TypedReplyBarState extends State<TypedReplyBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty || !widget.enabled) return;
    _controller.clear();
    widget.onSubmit(text);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('typed-reply-field'),
              controller: _controller,
              enabled: widget.enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                isDense: true,
                hintText: 'Type your reply…',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Send typed reply',
            onPressed: widget.enabled ? _submit : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
