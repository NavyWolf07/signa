import 'package:go_router/go_router.dart';

import '../../features/entries/presentation/screens/home_screen.dart';
import '../../features/entries/presentation/screens/editor_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

final appRouter = GoRouter(
  // Uygulama açılınca ilk gidilecek ekran
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/editor',
      name: 'editor-new',
      builder: (context, state) {
        final initialDate = state.extra as DateTime?;
        return EditorScreen(initialDate: initialDate);
      },
    ),
    GoRoute(
      path: '/editor/:id',
      name: 'editor-edit',
      builder: (context, state) {
        // URL'den id'yi alıyoruz — mesela /editor/5
        final id = int.parse(state.pathParameters['id']!);
        return EditorScreen(entryId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
