/// Top-left corner of the desktop window, in logical pixels.
///
/// Carries plain doubles instead of `Offset` so it can cross the repository
/// boundary — repositories stay free of Flutter imports.
class WindowPosition {
  final double x;
  final double y;

  const WindowPosition({required this.x, required this.y});

  /// False when a stored value came back as `NaN` or infinity — a corrupt
  /// preference must never reach the window manager.
  bool get isFinite => x.isFinite && y.isFinite;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowPosition &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'WindowPosition(x: $x, y: $y)';
}
