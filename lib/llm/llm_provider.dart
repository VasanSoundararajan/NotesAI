abstract class LlmProvider {
  /// Summarise the provided [text]. Optionally provide [maxTokens].
  Future<String> summarize(String text, {int? maxTokens});
}