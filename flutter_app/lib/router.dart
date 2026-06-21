import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/supabase_client.dart';
import 'providers/providers.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/shell_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/pipeline_screen.dart';
import 'ui/screens/deal_detail_screen.dart';
import 'ui/screens/clients_screen.dart';
import 'ui/screens/client_detail_screen.dart';
import 'ui/screens/ai_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/module_screen.dart';
import 'ui/screens/messages_screen.dart';
import 'ui/screens/channel_screen.dart';
import 'ui/screens/tasks_screen.dart';
import 'ui/screens/notes_screen.dart';
import 'ui/screens/note_editor_screen.dart';
import 'ui/screens/projects_screen.dart';
import 'ui/screens/project_detail_screen.dart';
import 'ui/screens/leads_screen.dart';
import 'ui/screens/approvals_screen.dart';
import 'ui/screens/credit_stack_screen.dart';
import 'ui/screens/settings_screen.dart';

/// Re-creates the router whenever auth state flips so redirects re-run.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loggedIn = supabase.auth.currentSession != null;
      final loggingIn = state.matchedLocation == '/login';
      if (!loggedIn) return loggingIn ? null : '/login';
      if (loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),

      // Bottom-nav shell: Home · Pipeline · ✦ AI · Clients · More
      StatefulShellRoute.indexedStack(
        builder: (context, state, navShell) =>
            ShellScreen(navigationShell: navShell),
        branches: [
          StatefulShellBranch(navigatorKey: shellKey, routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/pipeline', builder: (_, _) => const PipelineScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/ai', builder: (_, _) => const AiScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/clients', builder: (_, _) => const ClientsScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          ]),
        ],
      ),

      // Stacked full-screen routes (hide the bottom nav)
      GoRoute(
        path: '/deal/:id',
        parentNavigatorKey: rootKey,
        builder: (_, s) => DealDetailScreen(dealId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/client/:id',
        parentNavigatorKey: rootKey,
        builder: (_, s) => ClientDetailScreen(clientId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/messages',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const MessagesScreen(),
      ),
      GoRoute(
        path: '/messages/:channel',
        parentNavigatorKey: rootKey,
        builder: (_, s) => ChannelScreen(channelId: s.pathParameters['channel']!),
      ),
      GoRoute(
        path: '/tasks',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const TasksScreen(),
      ),
      GoRoute(
        path: '/notes',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const NotesScreen(),
      ),
      GoRoute(
        path: '/notes/:id',
        parentNavigatorKey: rootKey,
        builder: (_, s) => NoteEditorScreen(noteId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ProjectsScreen(),
      ),
      GoRoute(
        path: '/projects/:id',
        parentNavigatorKey: rootKey,
        builder: (_, s) => ProjectDetailScreen(projectId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/leads',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const LeadsScreen(),
      ),
      GoRoute(
        path: '/approvals',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const ApprovalsScreen(),
      ),
      GoRoute(
        path: '/credit-stack',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const CreditStackScreen(),
      ),
      GoRoute(
        path: '/settings',
        parentNavigatorKey: rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      // Generic adaptive module screen for everything else.
      GoRoute(
        path: '/module/:id',
        parentNavigatorKey: rootKey,
        builder: (_, s) => ModuleScreen(moduleId: s.pathParameters['id']!),
      ),
    ],
  );
});
