---
title: Verification Interfaces
description: Verification interfaces supported by DUT files and all programming languages
categories: [Tutorial]
tags: [docs]
weight: 1
---

## Generated Library Files

Picker can specify the target language for conversion using the `--lang` parameter (supported values: cpp, python, java, lua, scala, golang). Since different programming languages use different types of “libraries,” the generated files will vary. For example, Java produces a JAR package, while Python generates a directory. Exporting a library for a specific language with picker requires xcomm support. You can check support status with `picker --check`:

```bash
$ picker --check
[OK ] Version: 0.9.0-feat_performance_improve-b7001a6-2025-04-11-dirty
[OK ] Exec path: /usr/local/share/lib/python3.11/site-packages/picker/bin/picker
[OK ] Template path: /usr/local/share/lib/python3.11/site-packages/picker/share/picker/template
[OK ] Support    Cpp (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/lib' success)
[OK ] Support Golang (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/golang' success)
[OK ] Support   Java (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/java/xspcomm-java.jar' success)
[OK ] Support    Lua (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/lua/luaxspcomm.so' success)
[OK ] Support Python (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/python' success)
[OK ] Support  Scala (find: '/usr/local/share/lib/python3.11/site-packages/picker/share/picker/scala/xspcomm-scala.jar' success)
```

A status of "success" means supported, while "fail" means not supported.

### C++

For C++, picker generates a shared object (`.so`) dynamic library and the corresponding header files. For example:

```bash
UT_Adder/
├── UT_Adder.cpp       # DUT source file
├── UT_Adder.hpp       # DUT header file
├── UT_Adder_dpi.hpp   # DPI header file
├── dut_base.hpp       # DUT base header file
├── libDPIAdder.a      # DPI static library
└── libUTAdder.so      # DUT dynamic library
```

When using, set the LD path, then `#include UT_Adder.hpp` in your test code.

### Python

For Python, picker generates a directory (Python modules are represented as directories):

```bash
UT_Adder/
├── _UT_Adder.so
├── __init__.py
├── libUTAdder.so
└── libUT_Adder.py
```

After setting the PYTHONPATH, you can `import UT_Adder` in your test code.

### Java/Scala

For Java and Scala (JVM-based languages), picker generates the corresponding JAR packages.

```bash
UT_Adder/
├── UT_Adder-scala.jar
└── UT_Adder-java.jar
```

### Go

For Go, picker generates a directory (similar to Python):

```bash
UT_Adder/
└── golang
    └── src
        └── UT_Adder
            ├── UT_Adder.go
            ├── UT_Adder.so
            ├── UT_Adder_Wrapper.go
            ├── go.mod
            └── libUTAdder.so
```

After setting the GOPATH, you can directly import the package.

## Verification Interfaces

For DUT verification interfaces, refer to: [https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md](https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md)

For xspcomm library interfaces, refer to: [https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md](https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md)
```
