---
title: 验证接口
description: DUT文件与编程语言都支持的验证接口
categories: [教程]
tags: [docs]
weight: 1
---

## 生成库文件

picker可以通过参数`--lang`指定转换的对应语言（参数已支持cpp、python、java、scala、golang），由于不同编程语言对应的“库”不同，因此生成的库文件有所区别，例如java生成的是jar包，python生成的为文件夹。picker导出对应编程语言的库，需要xcomm的支持，可以通过`picker --check`查看支持情况：

```bash
$picker --check
[OK ] Version: 0.9.0---dirty
[OK ] Exec path: /home/yaozhicheng/mambaforge/lib/python3.11/site-packages/picker/bin/picker
[OK ] Template path: /home/yaozhicheng/mambaforge/lib/python3.11/site-packages/picker/share/picker/template
[OK ] Support    Cpp (find: '/home/yaozhicheng/mambaforge/lib/python3.11/site-packages/picker/share/picker/include' success)
[Err] Support   Java (find: 'java/xspcomm-java.jar' fail)
[Err] Support  Scala (find: 'scala/xspcomm-scala.jar' fail)
[OK ] Support Python (find: '/home/yaozhicheng/mambaforge/lib/python3.11/site-packages/picker/share/picker/python' success)
[Err] Support Golang (find: 'golang' fail)
```

输出显示success表示支持，fail表示不支持。

### C++

对于C++语言，picker生成的为so动态链接库，和对应的头文件。例如：

```bash
UT_Adder/
├── UT_Adder.cpp       # DUT 文件
├── UT_Adder.hpp       # DUT 头文件
├── UT_Adder_dpi.hpp   # DPI 头文件
├── dut_base.hpp       # DUT base 头文件
├── libDPIAdder.a      # DPI 静态库
└── libUTAdder.so      # DUT 动态库
```

在使用时，设置好LD路径，然后再测试代码中`#include UT_Adder.hpp`

### Python

Python语言生成的为目录（Python module以目录的方式表示）

```bash
UT_Adder/
├── _UT_Adder.so
├── __init__.py
├── libUTAdder.so
└── libUT_Adder.py
```

设置PYTHONPATH后，可以在test中`import UT_Adder`

### Java/scala

对于Java和scala基于JVM的编程语言，picker生成的为对应的jar包。

```bash
UT_Adder/
├── UT_Adder-scala.jar
└── UT_Adder-java.jar
```

### go

go语言生成的为目录（类似python）。

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

设置GOPATH后，可直接进行import

## 验证接口


DUT验证接口可以参考连接：[https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md](https://github.com/XS-MLVP/picker/blob/master/doc/API.zh.md)


xspcomm库接口请参考连接：[https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md](https://github.com/XS-MLVP/xcomm/blob/master/docs/APIs.cn.md)
