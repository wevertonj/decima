/// Canto superior esquerdo da janela desktop, em pixels lógicos.
///
/// Trafega `double` puro em vez de `Offset` para cruzar a fronteira dos
/// repositórios — repositórios não importam Flutter.
class WindowPosition {
  final double x;
  final double y;

  const WindowPosition({required this.x, required this.y});

  /// `false` quando o valor gravado voltou como `NaN` ou infinito — uma
  /// preferência corrompida nunca pode chegar ao window manager.
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
