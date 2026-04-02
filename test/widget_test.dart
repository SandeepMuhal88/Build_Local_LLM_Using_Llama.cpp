import 'package:flutter_test/flutter_test.dart';
import 'package:local_llm_assistant/main.dart';

void main() {
  testWidgets('App launches without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const LocalLlmApp());
    await tester.pump();

    // Verify the app renders (splash screen shows app name)
    expect(find.text('Local LLM'), findsOneWidget);
  });
}
