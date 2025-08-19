---
title: 覆盖率统计
description: 覆盖率工具
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 4
---

> Picker 工具支持生成代码行覆盖率报告，toffee-test（[https://github.com/XS-MLVP/toffee-test](https://github.com/XS-MLVP/toffee-test)） 项目支持生成功能覆盖率报告。

## 代码行覆盖率

目前 Picker 工具支持基于 Verilator 仿真器生成的代码行覆盖率报告。

### Verilator

Verilator 仿真器提供了[覆盖率支持](https://verilator.org/guide/latest/exe_verilator_coverage.html)功能。
该功能的实现方式是：

1. 利用 `verilator_coverage` 工具处理或合并覆盖率数据库，最终针对多个 DUT 生成一个 `coverage.info` 文件。
2. 利用 `lcov` 工具的 `genhtml` 命令基于`coverage.info`和 RTL 代码源文件，生成完整的代码覆盖率报告。

使用时的流程如下：

1. 使用 Picker 生成 dut 时，使能 COVERAGE 功能 （添加`-c`选项）。
2. 仿真器运行完成后，`dut.Finish()` 之后会生成覆盖率数据库文件 `V{DUT_NAME}.dat`。
3. 基于 `verilator_coverage` 的 write-info 功能将其转换成 `.info`文件。
4. 基于 `lcov` 的 `genhtml` 功能，使用`.info`文件和文件中指定的**rtl 源文件**，生成 html 报告。

> 注意： 文件中指定的**rtl 源文件**是指在生成的`DUT`时使用的源文件路径，需要保证这些路径在当前环境下是有效的。简单来说，需要编译时用到的所有`.sv/.v`文件都需要在当前环境下存在，并且目录不变。

#### verilator_coverage

`verilator_coverage` 工具用于处理 `DUT` 运行后生成的 `.dat` 的覆盖率数据。该工具可以处理并合并多个 `.dat` 文件，同时具有两类功能：

1. 基于 `.dat` 文件生成 `.info` 文件，用于后续生成网页报告。

   - `-annotate <output_dir>`：以标注的形式在源文件中呈现覆盖率情况，结果保存到`output_dir`中。形式如下：

     ```sv
     100000  input logic a;   // Begins with whitespace, because
                             // number of hits (100000) is above the limit.
     %000000  input logic b;   // Begins with %, because
                             // number of hits (0) is below the limit.
     ```

   - `-annotate-min <count>`：指定上述的 limit 为 count

2. 可以将 `.dat` 文件，结合源代码文件，将覆盖率数据以标注的形式与源代码结合在一起，并写入到指定目录。

   - `-write <merged-datafile> -read <datafiles>`：将若干个.dat(`datafiles`)文件合并为一个.dat 文件
   - `-write-info <merged-info> -read <datafiles>`：将若干个.dat(`datafiles`)文件合并为一个.info 文件

#### genhtml

由 `lcov` 包提供的 `genhtml` 可以由上述的.info 文件导出可读性更好的 html 报告。命令格式为：`genhtml [OPTIONS] <infofiles>`。
建议使用`-o <outputdir>`选项将结果输出到指定目录。

以[加法器](/docs/quick-start/eg-adder/)为例。

![adder.jpg](adder.jpg)

## 使用示例

如果您使用 Picker 时打开了`-c`选项，那么在仿真结束后，会生成一个`V{DUT_NAME}.dat`文件。并且顶层目录会有一个 Makefile 文件，其中包含了生成覆盖率报告的命令。

命令内容如下：

```make
coverage:
    ...
    verilator_coverage -write-info coverage.info ./${TARGET}/V${PROJECT}_coverage.dat
    genhtml coverage.info --output-directory coverage
    ...
```

在 shell 中输入`make coverage`,其会根据生成的.dat 文件生成 coverage.info，再使用`genhtml`再 coverage 目录下生成 html 报告。

## VCS

VCS 对应的文档正在完善当中。
