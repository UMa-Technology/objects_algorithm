# Third-party notices

objects_algorithm includes code from the following projects. Each keeps its own license.

## AA+

- Source: <http://www.naughter.com/aa.html>
- Location: `flutter/objects_algorithm/src/aaplus/`
- Version: 2.75 (9 September 2026)
- Copyright (c) 2003 - 2026 by PJ Naughter

The AA+ source files are vendored byte-identical to the author's release (including its CRLF line
endings and comment encoding; `.gitattributes` keeps git from converting them). Only files are
omitted, never changed: the upstream Visual Studio/CMake project files, the `AA+.h.in` template
(the release ships the generated `AA+.h`) and the HTML documentation. The copyright and usage
details at the top of each module apply and are reproduced here:

> You are allowed to include the source code in any product (commercial, shareware, freeware or
> otherwise) when your product is released in binary form. You are allowed to modify the source
> code in any way you want except you cannot modify the copyright details at the top of each
> module. If you want to distribute source code with your application, then you are only allowed
> to distribute versions released by the author. This is to maintain a single distribution point
> for the source code.

## SwiftAA

- Source: <https://github.com/onekiloparsec/SwiftAA>
- Location: `flutter/objects_algorithm/src/aainterface/` (the `extern "C"` bridge layer is derived
  from SwiftAA's `KPCAA*` interface layer)
- Copyright (c) Cédric Foellmi

```
The MIT License (MIT)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
