import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

/// OptionCard - Primary building block for MCQ and single-select flows
class OptionCard extends StatefulWidget {
  final String id;
  final String label;
  final String? subtitle;
  final Widget? icon;
  final bool selected;
  final bool disabled;
  final Function(String) onSelect;
  final OptionCardVariant variant;

  const OptionCard({
    super.key,
    required this.id,
    required this.label,
    this.subtitle,
    this.icon,
    required this.selected,
    this.disabled = false,
    required this.onSelect,
    this.variant = OptionCardVariant.defaultVariant,
  });

  @override
  State<OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<OptionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.cardPressDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: AppTheme.defaultCurve),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.disabled) {
      _controller.forward().then((_) => _controller.reverse());
      widget.onSelect(widget.id);
    }
  }

  double get _height {
    switch (widget.variant) {
      case OptionCardVariant.compact:
        return 56.0;
      case OptionCardVariant.large:
        return 110.0;
      case OptionCardVariant.defaultVariant:
        return 64.0; // Minimum height, will grow with content
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: AppTheme.fadeInDuration,
          curve: AppTheme.defaultCurve,
          constraints: BoxConstraints(
            minHeight: _height,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: widget.selected
                ? const Color(0xFFFFF7F4)
                : AppTheme.surfaceColor(context),
            border: Border.all(
              color: widget.selected
                  ? AppTheme.primaryColor(context)
                  : AppTheme.borderColor(context),
              width: widget.selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow:
                widget.selected ? AppTheme.selectedShadow : AppTheme.defaultShadow,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                SizedBox(width: 40, child: widget.icon),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.label,
                      style: AppTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: AppTheme.caption,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.selected)
                Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor(context),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum OptionCardVariant { compact, defaultVariant, large }

/// PrimaryButton - Main CTA button
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;
  final bool loading;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
          child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor(context),
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.primaryColor(context).withOpacity(0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// GhostButton - Secondary/outline button
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool fullWidth;

  const GhostButton({
    super.key,
    required this.label,
    this.onPressed,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.colorText,
          side: BorderSide(color: AppTheme.borderColor(context), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// ToggleChip - Chip for multi-select options
class ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onToggle;

  const ToggleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: AppTheme.fadeInDuration,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary400Color(context) : AppTheme.surfaceColor(context),
          border: Border.all(
            color: selected ? AppTheme.primaryColor(context) : AppTheme.borderColor(context),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
            color: Theme.of(context).textTheme.bodyLarge?.color ?? AppTheme.colorText,
          ),
        ),
      ),
    );
  }
}

