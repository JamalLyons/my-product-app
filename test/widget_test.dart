import 'package:flutter_test/flutter_test.dart';
import 'package:my_product_app/main.dart';

void main() {
  testWidgets('shows Firebase setup instructions when not configured', (tester) async {
    await tester.pumpWidget(const ProductApp(firebaseSetupError: 'not configured'));
    expect(find.textContaining('Firebase is not configured'), findsOneWidget);
  });
}
