## 0.2.0

* First public release: English documentation and comments, MIT license, third-party notices.
* Upgraded the vendored AA+ from 2.61 to 2.75, kept byte-identical to the author's release.
  Results move by at most a fraction of an arcsecond (updated Delta T table) and moon phase times
  by under a second. The exported `KPCAAAngularSeparation_PositionAngle` and
  `KPCAAElementsPlanetaryOrbit_EarthLongitudePerihelion*` now return corrected values (upstream
  bug fixes), and `KPCAADate_DateToJulianDay` returns NaN for out-of-range months or days.
* Documented that iOS host apps must set `STRIP_STYLE = non-global` for Release builds; the
  example app now does.

## 0.1.1

* macOS: export only `KPCAA*` and the plugin class from the dynamic framework and enable
  dead-stripping, dropping the unused AA+ coefficient tables.

## 0.1.0

* Restructured into a four-platform (Android, iOS, macOS, Windows) Flutter FFI plugin that
  compiles AA+ and the bridge layer from source on every platform.
* Observing-night window and solar events via `astroNightForSiteDate`, independent of the site's
  time zone label; `timesForWindow` for the Sun and planets; the Sun's upper-transit altitude.

## 0.0.1

* Initial version.
