import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// Regression: the invisible [EditableText] must keep painting, otherwise the
/// selection overlay's [LayerLink] has no leader and the paste toolbar is both
/// invisible and untappable — silently disabling `enablePaste`.
void main() {
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return <String, dynamic>{'text': '123456'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  Future<String> longPressAndPaste(WidgetTester tester,
      {bool enablePaste = true}) async {
    var pin = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: MaterialPinField(
              length: 6,
              enablePaste: enablePaste,
              keyboardType: TextInputType.number,
              onChanged: (value) => pin = value,
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.longPress(find.byType(MaterialPinField));
    await tester.pump(const Duration(seconds: 1));

    final paste = find.text('Paste');
    if (paste.evaluate().isEmpty) return pin;

    // warnIfMissed is left on: an unlinked follower renders the button but
    // fails to hit test, which is exactly the bug guarded here.
    await tester.tap(paste);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    return pin;
  }

  testWidgets('paste toolbar is tappable and fills the pin', (tester) async {
    expect(await longPressAndPaste(tester), '123456');
  });

  testWidgets('no paste toolbar when enablePaste is false', (tester) async {
    expect(await longPressAndPaste(tester, enablePaste: false), '');
    expect(find.text('Paste'), findsNothing);
  });
}
