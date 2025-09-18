import 'package:flutter_test/flutter_test.dart';
import 'package:vegnbio_front/main.dart';
import 'package:vegnbio_front/screens/home/home_screen.dart';

void main() {
  testWidgets('App should render home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('VegnBio'), findsOneWidget);
    expect(find.text('À propos de VegnBio'), findsOneWidget);
    expect(find.text('Nos Horaires'), findsOneWidget);
  });

  testWidgets('Home screen should display opening hours', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Lundi'), findsOneWidget);
    expect(find.text('9h00 - 19h00'), findsAtLeastNWidgets(5)); // Du lundi au vendredi
    expect(find.text('Dimanche'), findsOneWidget);
    expect(find.text('Fermé'), findsOneWidget);
  });
}