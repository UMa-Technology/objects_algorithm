# App Call Guidance: Solar Events and the Observing-Night Window

This document is for host-app developers. Goal: a single call that returns sunrise, solar transit, sunset, the three kinds of twilight, and the observing-night window, for drawing altitude curves and day/night segmentation.

## Recommended entry point

Use `astroNightForSiteDate(...)`.

```dart
import 'package:objects_algorithm/objects_algorithm.dart';

final result = astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.now().toUtc(),
  obs: Geography(48.8566, 2.3522),
);
```

## Input rules

- `timezoneName`: the IANA time zone name of the observing site, e.g. `Europe/Paris`, `Asia/Shanghai`, `Asia/Singapore`. Do not pass a UTC offset.
- `nowUtc`: the moment being evaluated. Must be a UTC `DateTime`.
- `obs`: latitude and longitude of the observing site. `Geography(lat, lon)`; east longitude is positive, west is negative.

The app does not need to pass site-day boundaries. The library uses `timezoneName` to convert `nowUtc` into the site's local day, then derives:

- start of the previous site day (UTC)
- start of the current site day (UTC)
- end of the current site day (UTC)
- end of the next site day (UTC)
- the previous site-local noon (UTC)
- the current site-local noon (UTC)
- the next site-local noon (UTC)

These boundaries are used internally only. 23- or 25-hour site days caused by daylight saving time are handled naturally by the IANA time zone data.

## Time zone initialization

The library lazily initializes the time zone database. The app does not need to call any initialization itself.

Behavior:

- If the app has already initialized the time zone database, the library uses it as is.
- If the app has not, the library initializes it on first call.
- Re-initializing from the app afterwards is generally safe.
- The library never calls `tz.setLocalLocation(...)` and never changes the app's global local time zone.

## Returned fields

`AstroNight` returns the night-window fields and the solar-event fields side by side at the same level.

Night-window fields:

- `status`: result status.
- `reason`: reason for the status.
- `startUtc`: start of the observing-night window; may be `null`.
- `endUtc`: end of the observing-night window; may be `null`.
- `startSource`: source of the start anchor; may be `null`.
- `endSource`: source of the end anchor; may be `null`.
- `curveStartUtc`: start of the curve canvas window, whose length is fixed at 24 hours; may be `null`.
- `todayDawnAnchorUtc`: the dawn anchor of the current site day; may be `null`.
- `todayDawnAnchorSource`: source of the dawn anchor; may be `null`.
- `sunTransitAltitudeDeg`: geometric altitude of the Sun at upper transit (the day's highest point), in degrees; may be `null`.

Solar-event fields:

- `riseTime`: sunrise.
- `transitTime`: solar transit.
- `setTime`: sunset.
- `civilDawn`: civil dawn, Sun altitude -6 degrees.
- `civilDusk`: civil dusk, Sun altitude -6 degrees.
- `nauticalDawn`: nautical dawn, Sun altitude -12 degrees.
- `nauticalDusk`: nautical dusk, Sun altitude -12 degrees.
- `astronomicalDawn`: astronomical dawn, Sun altitude -18 degrees.
- `astronomicalDusk`: astronomical dusk, Sun altitude -18 degrees.

All solar-event fields are `DateTime?`. At high latitudes, and during polar day or polar night, some events do not exist and are returned as `null`. The app must handle `null` and must not invent placeholder times.

The solar-event fields are meant for the app's curves, and all of them are taken from a single window: `[curveStartUtc, curveStartUtc + 24h)`.

**To draw the x axis and day/night segments, use `curveStartUtc` directly. Do not compute noon yourself from the site date.**

How `curveStartUtc` is chosen:

- In the normal case it is the site-local `12:00` of the site day that the current observing night belongs to (yesterday's noon in the small hours, today's noon otherwise), matching the earlier behavior.
- When the site time zone badly mismatches the site longitude (a mocked location, or a device whose time zone was not updated after crossing zones), site-local noon falls in the local middle of the night. Any noon anchor would then split the night in two and push sunset and sunrise outside the window. In that case it falls back to "local apparent solar noon" (the middle of the night minus 12 hours). The start is no longer on the hour, but the night is always centered on the canvas.
- Polar day and polar night: no night anchor is available, so the window runs from the current site-local `12:00` to `12:00` the next day.

`todayDawnAnchorUtc` is the first available dawn anchor within the current site day, in priority order `astronomicalDawn -> nauticalDawn -> civilDawn -> riseTime`. It is only a hint for the app to decide "which night we are in"; the curve window is always `curveStartUtc`.

For `noWindow` and `invalidInput`, `curveStartUtc` is `null` and the app needs its own fallback.

## Status handling

Status codes:

- `AstroNightStatus.complete == 0`
- `AstroNightStatus.polarNight == 1`
- `AstroNightStatus.polarDay == 2`
- `AstroNightStatus.noWindow == 3`
- `AstroNightStatus.invalidInput == 4`

`status` is returned as an `int` so the app can parse it directly. On the Dart side you can still compare against constants such as `AstroNightStatus.complete`.

`AstroNightStatus.complete` (`0`)

- A usable night window exists.
- `startUtc` and `endUtc` are normally non-null.
- Solar events are still returned where possible; missing events are `null`.

`AstroNightStatus.polarNight` (`1`)

- Polar night, or the Sun stays below the rise/set threshold all day.
- `startUtc` and `endUtc` span the whole site day.
- `startSource == siteDayStartUtc`, `endSource == siteDayEndUtc`.
- The app may highlight the whole site day as night.
- Solar events are still returned where possible; missing events are `null`.

`AstroNightStatus.polarDay` (`2`)

- Polar day, or the Sun stays above the rise/set threshold all day.
- `startUtc` and `endUtc` are `null`.
- The app should not draw an observing-night window.
- Any solar-event fields that do exist, such as `transitTime`, can still be used.

`AstroNightStatus.noWindow` (`3`)

- The input is valid, but no usable night window could be found. This is not expected in normal use; it is kept as a safety net.
- `startUtc`, `endUtc` and `curveStartUtc` are `null`.
- Solar events are still returned where possible (taken from the current site day; they do not form a complete 24-hour curve window).
- Possible `reason` values:
  - `dusk and dawn fallback exhausted`: none of the four fallback tiers (astronomical -> nautical -> civil -> rise/set) could produce a dusk -> dawn pair.
  - `window inverted`: the computed start is not earlier than the end.
  - `polar undetermined`: no sunrise/sunset, and it cannot be determined whether the Sun is above or below the threshold all day.

A missing `todayDawnAnchorUtc` **no longer** causes `noWindow`; it is only a reference field. In high-latitude transition seasons (e.g. Tromso in late July, just after leaving polar day) a site day may contain only a sunset and no twilight or sunrise at all, but the night itself exists and is returned normally.

Historical issues (fixed, 2026-08):

- Night anchors used to be paired as "dusk later than dawn within the same site day". When the site time zone mismatched the site longitude (a mocked location, or a device time zone not updated after crossing zones), the site day was cut during local daytime, the order within the window became dusk -> dawn, and the result was consistently `noWindow` + `dusk fallback exhausted`.
- Anchor fallback used to be decided per window independently. In high-latitude transition seasons it is common to have "no astronomical dusk today, astronomical dawn tomorrow"; mixing tiers produced dusk -> dawn pairs that reached into another night, giving night lengths of 26 hours or more.

Anchors are now collected over contiguous windows aligned to whole UTC days, the fallback chain is applied uniformly per tier, and the search descends tier by tier based on whether a complete night can be formed. By design, the result is independent of the time zone label: for the same site and the same moment, any `timezoneName` yields the same `startUtc/endUtc` for `complete` (except polar day/night, whose windows are by definition this day on the site's calendar).

`AstroNightStatus.invalidInput` (`4`)

- `timezoneName` is not an IANA name, or `nowUtc` is not UTC.
- Night-window fields are `null`.
- Solar-event fields stay `null`.

## Curve drawing recommendations

Use the solar-event fields as the main split points of the altitude curve.

All solar-event fields fall within `[curveStartUtc, curveStartUtc + 24h)`; use this interval directly as the x axis.

- `curveStartUtc != null`: draw a 24-hour axis from it; the 9 events land on the axis naturally.
- `curveStartUtc == null` (`noWindow` / `invalidInput`): the app may draw only the available event points, without full day/night segmentation.

Preferred order:

1. `astronomicalDawn`
2. `nauticalDawn`
3. `civilDawn`
4. `riseTime`
5. `transitTime`
6. `setTime`
7. `civilDusk`
8. `nauticalDusk`
9. `astronomicalDusk`

Filter out `null` first, then sort by UTC time. Do not assume all 9 fields exist, and do not assume dawn falls on the same UTC date. For a site day in UTC+8 that crosses a UTC day boundary, dawn may fall on the previous UTC day.

For night shading or the observing window use:

- `startUtc`
- `endUtc`
- `startSource`
- `endSource`

The 9 solar-event fields are for curve segmentation; `startUtc/endUtc` is for the observing-night highlight. They serve different purposes.

Suggested app handling by status:

- `complete`: draw the curve and the `startUtc/endUtc` highlight.
- `polarDay`: the curve may be drawn; no night highlight; show a polar-day note.
- `polarNight`: draw the curve; highlight the whole site day as night; show a polar-night note.
- `noWindow`: the available event points may be drawn; no night highlight; show `reason`.
- `invalidInput`: do not draw the curve; report a site configuration error.

## Curve dates for non-solar targets

For altitude curves of targets such as M31, planets or the Moon, the app should compute target altitude over **the same** 24-hour window as the solar curve, i.e. `[curveStartUtc, curveStartUtc + 24h)`. Only when both come from the same source does the day/night shading line up exactly with the target's altitude curve.

- `complete` / `polarDay` / `polarNight`: `curveStartUtc` is non-null; use it directly.
- `noWindow` / `invalidInput`: `curveStartUtc` is `null`. If the app has a user-selected date, use that date's local-noon window; for `invalidInput` it is recommended not to draw the curve.

The solar-event fields are only for solar-curve markers and as a day/night segmentation reference. For non-solar targets such as M31, use the window above and compute altitude from the target's right ascension and declination, the observing site, and the UTC time of each sample.

### Sampling window for diurnal paths on a sky chart

When a host app draws a target's whole-night track on the sky (a diurnal path sampler living in the app, not shipped with this plugin), the same line usually carries time labels, a highlighted "shootable" segment and a transit marker. All three are computed for the night the caller specified, so **the sampling window must use the same anchor**:

```dart
// `anchor` is the 24 h curve-window start for the chosen night,
// e.g. `night.curveStartUtc` from astroNightForSiteDate(...).
final path = sampleDiurnalPath(   // host-app function, not part of this plugin
  ra, dec, stepMinutes,
  referenceTime: engineTime,  // horizontal reference frame = the render engine's current time; decides whether the circle matches the on-screen sky
  rangeStart: anchor,         // sampling window = the same 24 h anchor as the labels
  la: la, lo: lo,
);
```

The window defaults to "tonight". If the caller labels the path for some other date (an offline plan picked a session a few days out, or the user dragged the sky-chart time away), the two drift apart by the corresponding number of days of sidereal time, **about 4 minutes per day**. A few days is visible to the eye; a few months and the labels no longer match at all.

Two parameters that are easy to confuse:

- `referenceTime` only decides which moment's horizontal reference frame the track is locked into; it does not change the sampled time range.
- `rangeStart` is the start of the 24-hour sampling window, shared with the time labels, the night segment and the transit index.

The observing site **does not affect the result**: in `eq(ti) -> hz(ti, site) -> eq(jdRef, site)` both legs use the same site and neither applies refraction, so the site cancels out exactly in the round trip. If refraction or apparent altitude is ever added to one of the legs, this cancellation no longer holds and every call site must be re-reviewed.

Example: `Europe/Oslo`, `nowUtc = 2026-06-21 12:00Z`, `status == polarDay`. Oslo is on CEST (UTC+2) that day, so `curveStartUtc == 2026-06-21 10:00Z`, i.e. local `2026-06-21 12:00` to `2026-06-22 12:00`.

## App-side example

```dart
final night = astroNightForSiteDate(
  timezoneName: siteTimezoneName,
  nowUtc: DateTime.now().toUtc(),
  obs: Geography(latitude, longitude),
);

final solarMarks = <String, DateTime?>{
  'astronomicalDawn': night.astronomicalDawn,
  'nauticalDawn': night.nauticalDawn,
  'civilDawn': night.civilDawn,
  'riseTime': night.riseTime,
  'transitTime': night.transitTime,
  'setTime': night.setTime,
  'civilDusk': night.civilDusk,
  'nauticalDusk': night.nauticalDusk,
  'astronomicalDusk': night.astronomicalDusk,
};

final curvePoints = solarMarks.entries
    .where((entry) => entry.value != null)
    .toList()
  ..sort((a, b) => a.value!.compareTo(b.value!));

if ((night.status == AstroNightStatus.complete ||
        night.status == AstroNightStatus.polarNight) &&
    night.startUtc != null &&
    night.endUtc != null) {
  // Draw the observing-night window highlight.
}

final curveStart = night.curveStartUtc;
if (curveStart != null) {
  final curveEnd = curveStart.add(const Duration(hours: 24));
  // x axis = [curveStart, curveEnd); solar events and non-solar target curves share this one window.
} else {
  // noWindow / invalidInput: draw only the available event points, or fall back to the local-noon window of a user-selected date.
}
```

## Test cases

The following cases come from `flutter/objects_algorithm/test/test.dart`. All times are UTC.

### Paris: before dawn

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.utc(2026, 5, 21, 0, 30),
  obs: Geography(48.8566, 2.3522),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-20 22:18Z`
- `endUtc`: `2026-05-21 01:18Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Paris: after dawn

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.utc(2026, 5, 21, 12),
  obs: Geography(48.8566, 2.3522),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 22:18Z`
- `endUtc`: `2026-05-22 01:17Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Invalid Timezone

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Mars/Olympus',
  nowUtc: DateTime.utc(2026, 5, 21, 12),
  obs: Geography(48.8566, 2.3522),
);
```

Expected:

- `status`: `invalidInput`
- `reason`: `invalid input`
- Night-window fields are `null`
- Solar-event fields are `null`

### Non-UTC nowUtc

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime(2026, 5, 21, 12),
  obs: Geography(48.8566, 2.3522),
);
```

Expected:

- `status`: `invalidInput`
- `reason`: `invalid input`

### Stockholm: deeper twilight missing

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Stockholm',
  nowUtc: DateTime.utc(2026, 5, 21, 12),
  obs: Geography(59.3293, 18.0686),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 20:34Z`
- `endUtc`: `2026-05-22 00:54Z`
- `startSource`: `civilDusk`
- `endSource`: `civilDawn`

### Reykjavik: all twilight missing

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Atlantic/Reykjavik',
  nowUtc: DateTime.utc(2026, 5, 21, 12),
  obs: Geography(64.1466, -21.9426),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 22:44Z`
- `endUtc`: `2026-05-22 04:04Z`
- `startSource`: `setTime`
- `endSource`: `riseTime`

### Asia/Shanghai: political time zone boundary

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Asia/Shanghai',
  nowUtc: DateTime.utc(2026, 5, 21, 10),
  obs: Geography(39.4704, 75.9898),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 16:00Z`
- `endUtc`: `2026-05-21 21:44Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Paris DST Start: 23-hour site day

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.utc(2026, 3, 29, 12),
  obs: Geography(-90, 0),
);
```

Expected:

- `status`: `polarNight`
- `reason`: `polar night all day`
- `startUtc`: `2026-03-28 23:00Z`
- `endUtc`: `2026-03-29 22:00Z`
- `startSource`: `siteDayStartUtc`
- `endSource`: `siteDayEndUtc`

### Paris DST End: 25-hour site day

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.utc(2026, 10, 25, 12),
  obs: Geography(90, 0),
);
```

Expected:

- `status`: `polarNight`
- `reason`: `polar night all day`
- `startUtc`: `2026-10-24 22:00Z`
- `endUtc`: `2026-10-25 23:00Z`
- `startSource`: `siteDayStartUtc`
- `endSource`: `siteDayEndUtc`

### Polar Day

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Oslo',
  nowUtc: DateTime.utc(2026, 6, 21, 12),
  obs: Geography(78.2232, 15.6469),
);
```

Expected:

- `status`: `polarDay`
- `reason`: `sun above rise/set threshold all day`
- `startUtc`: `null`
- `endUtc`: `null`

### Polar Night

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Europe/Oslo',
  nowUtc: DateTime.utc(2026, 12, 21, 12),
  obs: Geography(78.2232, 15.6469),
);
```

Expected:

- `status`: `polarNight`
- `reason`: `polar night all day`
- `startUtc`: `2026-12-20 23:00Z`
- `endUtc`: `2026-12-21 23:00Z`
- `startSource`: `siteDayStartUtc`
- `endSource`: `siteDayEndUtc`

### Singapore: full set of solar events

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Asia/Singapore',
  nowUtc: DateTime.utc(2026, 5, 21, 12),
  obs: Geography(1.3521, 103.8198),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 12:20Z`
- `endUtc`: `2026-05-21 21:42Z`
- `riseTime`: `2026-05-21 22:59:17Z`
- `transitTime`: `2026-05-21 05:01:18Z`
- `setTime`: `2026-05-21 11:06:41Z`
- `civilDawn`: `2026-05-21 22:33:43Z`
- `civilDusk`: `2026-05-21 11:29:10Z`
- `nauticalDawn`: `2026-05-21 22:08:02Z`
- `nauticalDusk`: `2026-05-21 11:54:43Z`
- `astronomicalDawn`: `2026-05-21 21:42:14Z`
- `astronomicalDusk`: `2026-05-21 12:20:28Z`

### New York: western-hemisphere DST time zone

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'America/New_York',
  nowUtc: DateTime.utc(2026, 5, 21, 16),
  obs: Geography(40.7128, -74.0060),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-22 02:08Z`
- `endUtc`: `2026-05-22 07:36Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Quito: western-hemisphere low latitude

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'America/Guayaquil',
  nowUtc: DateTime.utc(2026, 5, 21, 17),
  obs: Geography(-0.1807, -78.4678),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-22 00:27Z`
- `endUtc`: `2026-05-22 09:53Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Sydney: southern-hemisphere winter

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Australia/Sydney',
  nowUtc: DateTime.utc(2026, 6, 21, 2),
  obs: Geography(-33.8688, 151.2093),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-06-21 08:23Z`
- `endUtc`: `2026-06-21 19:30Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Kiritimati: positive-offset time zone at the date line

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Pacific/Kiritimati',
  nowUtc: DateTime.utc(2026, 5, 21),
  obs: Geography(1.8721, -157.4278),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 05:46Z`
- `endUtc`: `2026-05-21 15:06Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Honolulu: negative-offset time zone at the date line

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Pacific/Honolulu',
  nowUtc: DateTime.utc(2026, 5, 21, 22),
  obs: Geography(21.3069, -157.8583),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-22 06:27Z`
- `endUtc`: `2026-05-22 14:28Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Kolkata: half-hour time zone

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Asia/Kolkata',
  nowUtc: DateTime.utc(2026, 5, 21, 6, 30),
  obs: Geography(22.5726, 88.3639),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 14:05Z`
- `endUtc`: `2026-05-21 22:00Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### Chatham: 45-minute time zone

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'Pacific/Chatham',
  nowUtc: DateTime.utc(2026, 5, 20, 23, 15),
  obs: Geography(-43.9535, -176.5597),
);
```

Expected:

- `status`: `complete`
- `startUtc`: `2026-05-21 06:06Z`
- `endUtc`: `2026-05-21 17:19Z`
- `startSource`: `astronomicalDusk`
- `endSource`: `astronomicalDawn`

### New York DST Start: 23-hour site day

Input:

```dart
astroNightForSiteDate(
  timezoneName: 'America/New_York',
  nowUtc: DateTime.utc(2026, 3, 8, 16),
  obs: Geography(90, 0),
);
```

Expected:

- `status`: `polarNight`
- `reason`: `polar night all day`
- `startUtc`: `2026-03-08 05:00Z`
- `endUtc`: `2026-03-09 04:00Z`
- `startSource`: `siteDayStartUtc`
- `endSource`: `siteDayEndUtc`

## Coverage summary

The current `_astroNightCases` cover representative latitude/longitude and time zone combinations:

- European mid-latitudes, DST start/end, before/after-dawn branches.
- An Asian political time zone boundary, UTC+8, and Singapore with the full set of solar events.
- Western-hemisphere mid and low latitudes: New York, Quito.
- Southern-hemisphere mid latitudes: Sydney, Chatham.
- Both sides of the date line: Kiritimati, Honolulu.
- Non-whole-hour time zones: Kolkata (half hour), Chatham (45 minutes).
- High-latitude twilight fallback, polar day, polar night.
- Invalid time zone, non-UTC `nowUtc`.

This is representative coverage, not an enumeration of every IANA time zone or every latitude/longitude. The newly added cases pass against the current implementation and have not exposed any night-window calculation failure.
