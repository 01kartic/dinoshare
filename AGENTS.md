## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
- Always run `flutter analyze` after any changes.
- After `flutter pub get`, patch `bonsoir_android` build.gradle: add `apply plugin: "org.jetbrains.kotlin.android"` after line 24. (The plugin uses a `kotlin {}` block but forgets to apply the Kotlin plugin.)
- Android `desugar_jdk_libs` version must stay ≥ 2.1.4 for `flutter_local_notifications` 21.x.