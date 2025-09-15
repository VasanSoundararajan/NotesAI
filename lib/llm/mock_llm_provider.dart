import 'llm_provider.dart';

class MockLlmProvider implements LlmProvider {
  @override
  Future<String> summarize(String text, {int? maxTokens}) async {
    // Keep deterministic behavior and be very fast (no delays)
    final parts = text
        .split(RegExp(r'[.!?]'))
        .where((e) => e.trim().isNotEmpty)
        .toList();
    final head = parts.isNotEmpty ? parts.first.trim() : '';
    if (head.isEmpty) return 'Summary: (empty note)';

    final maxLen = 140;
    final truncated = head.substring(0, head.length.clamp(0, maxLen));
    return 'Summary: $truncated…';
  }
}