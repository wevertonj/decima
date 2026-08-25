/// Abstração da área de transferência da plataforma: a calculadora copia
/// e cola sem depender do `Clipboard` do Flutter (e é mockável em teste).
abstract class ClipboardService {
  /// Escreve [text] na área de transferência do sistema.
  Future<void> copyText(String text);

  /// Lê o texto da área de transferência. Retorna `null` quando vazia ou
  /// com conteúdo não textual.
  Future<String?> readText();
}
