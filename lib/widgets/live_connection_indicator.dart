import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveConnectionIndicator extends StatefulWidget {
  final bool isConnected;

  const LiveConnectionIndicator({
    Key? key,
    required this.isConnected,
  }) : super(key: key);

  @override
  State<LiveConnectionIndicator> createState() => _LiveConnectionIndicatorState();
}

class _LiveConnectionIndicatorState extends State<LiveConnectionIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.isConnected
            ? Colors.red.withOpacity(0.2)
            : Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isConnected ? Colors.red : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isConnected)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.5 + (_controller.value * 0.5),
                  child: const Icon(
                    Icons.circle,
                    color: Colors.red,
                    size: 10,
                  ),
                );
              },
            ),
          if (!widget.isConnected)
            const Icon(
              Icons.circle,
              color: Colors.grey,
              size: 10,
            ),
          const SizedBox(width: 8),
          Text(
            widget.isConnected ? 'LIVE' : 'OFFLINE',
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
