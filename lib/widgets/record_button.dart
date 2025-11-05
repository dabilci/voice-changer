import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class RecordButton extends StatefulWidget {
  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onPressed;

  const RecordButton({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    required this.onPressed,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
  }

  @override
  void didUpdateWidget(RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isProcessing && !oldWidget.isProcessing) {
      _rotationController.repeat();
    } else if (!widget.isProcessing && oldWidget.isProcessing) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isProcessing ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _rotationAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: widget.isProcessing ? _rotationAnimation.value * 2 * 3.14159 : 0,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _getButtonGradient(),
                  boxShadow: _getBoxShadow(),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ana ikon
                    Icon(
                      _getButtonIcon(),
                      size: 48,
                      color: Colors.white,
                    ),
                    
                    // Loading indicator (sadece processing durumunda)
                    if (widget.isProcessing)
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    
                    // Kayıt durumunda dış halka animasyonu
                    if (widget.isRecording)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _getButtonGradient() {
    if (widget.isProcessing) {
      return const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFFF5722)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    } else if (widget.isRecording) {
      return AppTheme.recordGradient;
    } else {
      return AppTheme.idleGradient;
    }
  }

  IconData _getButtonIcon() {
    if (widget.isProcessing) {
      return Icons.hourglass_empty;
    } else if (widget.isRecording) {
      return Icons.stop;
    } else {
      return Icons.mic;
    }
  }

  List<BoxShadow> _getBoxShadow() {
    final color = widget.isRecording 
        ? Colors.red.withOpacity(0.4)
        : Theme.of(context).colorScheme.primary.withOpacity(0.3);
    
    return [
      BoxShadow(
        color: color,
        blurRadius: widget.isRecording ? 20 : 15,
        spreadRadius: widget.isRecording ? 5 : 2,
        offset: const Offset(0, 8),
      ),
    ];
  }
} 