import 'package:flutter_test/flutter_test.dart';
import 'package:internship_task_vasansoundararajan/llm/mock_llm_provider.dart';

void main() {
  test('MockLlmProvider returns deterministic summary', () async {
    final p = MockLlmProvider();
    final text = 'Hello world. This is a second sentence.';
    final s = await p.summarize(text);
    expect(s.startsWith('Summary:'), true);
    expect(s.contains('Hello world'), true);
  });
}