# objects_algorithm

[English](README.md) | 简体中文

面向 Flutter 与 Dart 的天文算法库，基于 C++ 天文算法库 [AA+](http://www.naughter.com/aa.html)，
通过 `dart:ffi` 提供给 Dart 调用。

Flutter 插件位于 [`flutter/objects_algorithm`](flutter/objects_algorithm)。各平台都直接从源码编译
AA+ 和一层很薄的 `extern "C"` 桥接层，宿主 App 不需要拷贝任何 C++ 文件或预编译的二进制库。

由 [UMa Technology](https://umainf.com) 开发维护。

## 功能

- 坐标转换（赤道坐标、地平坐标、黄道坐标），岁差、章动、大气折射、视差
- 太阳、月球、行星与彗星的位置
- 升起、中天、落下时间
- 晨昏蒙影（民用、航海、天文）以及指定地点和日期的观测夜窗口
- 儒略日转换
- 月相与月面被照亮比例

## 平台

Android、iOS、macOS 和 Windows。

## 快速上手

- 集成方式、目录结构、Apple 端符号保活机制与构建验证：
  [flutter/objects_algorithm/README.md](flutter/objects_algorithm/README.md)（英文）
- 太阳事件与观测夜窗口（`astroNightForSiteDate`）的调用指南：
  [docs/app_call_guidance.md](docs/app_call_guidance.md)（英文）
- 插件 Dart 层的职责边界：[docs/scope.md](docs/scope.md)（英文）

```dart
import 'package:objects_algorithm/objects_algorithm.dart';

final night = astroNightForSiteDate(
  timezoneName: 'Europe/Paris',
  nowUtc: DateTime.now().toUtc(),
  obs: Geography(48.8566, 2.3522),
);
```

> iOS 宿主 App 需要把 Runner target 的 Release 配置设为 `STRIP_STYLE = non-global`
> （Strip Style：Non-Global Symbols），否则归档上架时 Xcode 会剥掉插件的全部符号。
> 详见插件 README。

## 致谢与第三方代码

- **AA+**，作者 PJ Naughter，是 Jean Meeus《Astronomical Algorithms》（天文算法）一书中算法的
  C++ 实现：<http://www.naughter.com/aa.html>。源码收录在 `flutter/objects_algorithm/src/aaplus/`
  下，适用 AA+ 自身的许可条款，详见 AA+ 官网及源码文件头部的说明。
- **SwiftAA**，作者 Cédric Foellmi（MIT 许可）：<https://github.com/onekiloparsec/SwiftAA>。
  `flutter/objects_algorithm/src/aainterface/` 下的 `extern "C"` 桥接层改编自 SwiftAA 的接口层。

完整声明见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)。

### 关于 SynLink App 中的 "AA+"

SynLink App 开源声明中列出的 "AA+"，指的是 PJ Naughter 开发的 AA+ 天文算法库
（<http://www.naughter.com/aa.html>）。SynLink 通过本项目使用该库，源码就收录在本仓库的
`flutter/objects_algorithm/src/aaplus/` 下。

## 许可证

objects_algorithm 采用 **MIT 许可证**（见 [LICENSE](LICENSE)）。第三方代码沿用各自的许可，如上所列；
其中收录的 AA+ 源码仍适用 AA+ 自身的条款。
