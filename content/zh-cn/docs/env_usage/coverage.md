---
title: 覆盖率统计
description: 覆盖率工具
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 4
---

> picker工具支持生成部分的覆盖率报告。
## **Verilator**
在使用verilator作为仿真器时，可以通过`verilator_coverage`工具以及`lcov`工具生成代码覆盖率报告。流程如下：
* 使用Picker生成dut时，打开`-c`选项
* 测试完成后生成.dat的覆盖率数据
* 使用`verilator_coverage`的write-info功能将其转换成.info文件
* 使用`lcov`的genhtml功能将.info文件转换成html报告

### **verilator_coverage**
`verilator_coverage`工具可以用来处理verilator生成的.dat的覆盖率数据。以下为一些简单的参数：
* **-annotate \<output_dir\>**：以标注的形式在源文件中呈现覆盖率情况，结果保存到**output_dir**中。形式如下：
```
100000  input logic a;   // Begins with whitespace, because
                          // number of hits (100000) is above the limit.
%000000  input logic b;   // Begins with %, because
                          // number of hits (0) is below the limit.
```
* **-annotate-min \<count\>**：指定上述的limit为count
* **-write \<merged-datafile\> -read \<datafiles\>**：将若干个.dat(`datafiles`)文件合并为一个.dat文件
* **-write-info \<merged-info\> -read \<datafiles\>**：将若干个.dat(`datafiles`)文件合并为一个.info文件

### **lcov(genhtml)**
`genhtml`可以由上述的.info文件导出可读性更好的html报告。命令格式为：`genhtml [OPTIONS] <infofiles>`。
建议使用`-o <outputdir>`选项将结果输出到指定目录。

### **示例**
如果您使用Picker时打开了verbose选项，在生成的目录下的Makefile文件中可以看到如下字段：
```make
coverage:
    ...
    verilator_coverage -write-info coverage.info ./${TARGET}/V${PROJECT}_coverage.dat
    genhtml coverage.info --output-directory coverage
    ...
```
其会根据生成的.dat文件生成coverage.info，再使用`genhtml`再coverage目录下生成html报告。


## **VCS**
TBD
