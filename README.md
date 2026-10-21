# objects_algorithm

English | [简体中文](README.zh-CN.md)

Astronomical algorithms for Flutter and Dart, built on the [AA+](http://www.naughter.com/aa.html)
C++ library and exposed to Dart through `dart:ffi`.

The Flutter plugin lives in [`flutter/objects_algorithm`](flutter/objects_algorithm). It compiles
the AA+ sources plus a thin `extern "C"` bridge layer from source on every platform, so host apps
never copy C++ files or prebuilt binaries.

Developed and maintained by [UMa Technology](https://umainf.com).

## Features

- Coordinate transforms (equatorial, horizontal, ecliptic), precession, nutation, refraction, parallax
- Positions of the Sun, the Moon, the planets and comets
- Rise, transit and set times
- Twilight (civil, nautical, astronomical) and the observing-night window for a site and date
- Julian date conversion
- Moon phases and illuminated fraction

## Platforms

Android, iOS, macOS and Windows.

## Getting started

- Integration, repository layout, the Apple symbol-keepalive mechanism and build verification:
  [flutter/objects_algorithm/README.md](flutter/objects_algorithm/README.md)
- Calling guide for solar events and the observing-night window (`astroNightForSiteDate`):
  [docs/app_call_guidance.md](docs/app_call_guidance.md)
- What belongs in the plugin's Dart layer: [docs/scope.md](docs/scope.md)

```dart
import 'package:objects_algorithm/objects_algorithm.dart';

final night = astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.now().toUtc(),
  obs: Geography(48.8566, 2.3522),
);
```

## Credits and third-party code

- **AA+** by PJ Naughter, a C++ implementation of the algorithms in Jean Meeus' *Astronomical
  Algorithms*: <http://www.naughter.com/aa.html>. Vendored under
  `flutter/objects_algorithm/src/aaplus/`. AA+ is distributed under its own license terms; see the
  AA+ website and the headers of the vendored sources.
- **SwiftAA** by Cédric Foellmi (MIT License): <https://github.com/onekiloparsec/SwiftAA>. The
  `extern "C"` bridge layer in `flutter/objects_algorithm/src/aainterface/` is derived from
  SwiftAA's interface layer.

The full notices are in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

### About "AA+" in the SynLink app

The open-source notice in the SynLink app credits "AA+". That entry refers to the AA+
astronomical algorithms library by PJ Naughter (<http://www.naughter.com/aa.html>), which
SynLink uses through this project and which is included here under
`flutter/objects_algorithm/src/aaplus/`.

## License

objects_algorithm is licensed under the **MIT License** (see [LICENSE](LICENSE)). Third-party
code keeps its own license, as listed above; in particular, the vendored AA+ sources remain under
AA+'s own terms.
