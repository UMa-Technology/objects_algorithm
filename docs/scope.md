# Plugin scope

The plugin's `lib/` contains only the pure-algorithm layer:

    astro.dart  bind.dart  comet.dart  coord.dart  earth.dart
    julian.dart moon.dart  planet.dart rise.dart   solar.dart  tools.dart

The rule for what belongs here: **no dependency on any host-app Service, Db, Entity or Assets.**
Code that needs an app's runtime environment (location or time zone services, persisted
preferences, localization, generated asset classes, database entities, UI helpers) lives in the
host app and calls into this plugin, not the other way round.

The boundary is enforced by `flutter analyze`: the plugin's only dependencies are `flutter`,
`ffi` and `timezone`, so any file that references an app-side symbol fails analysis immediately
with an undefined-name error.
