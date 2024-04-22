---
title: 多文件输入
description: 处理多个Verilog源文件
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 42
---

在许多情况中，某文件下的某个模块会例化其他文件下的模块，在这种情况下您可以使用Picker工具的`-f`选项处理多个verilog源文件。例如，假设您有`Cache.sv`, `CacheStage.sv`以及`CacheMeta.sv`三个源文件：  
```verilog
// In Cache.sv
module Cache(
    ...
);
    CacheStage s1(
        ...
    );

    CacheStage s2(
        ...
    );

    CacheStage s3(
        ...
    );

    CacheMeta cachemeta(
        ...
    );
endmodule

// In CacheStage.sv
module CacheStage(
    ...
);
    ...
endmodule

// In CacheMeta.sv
module CacheMeta(
    ...
);
    ...
endmodule
```  
其中，待测模块为Cache，位于`Cache.sv`中，则您可以通过以下命令生成指定语言的DUT：  
```bash
picker Cache.sv -f CacheStage.sv,CacheMeta.sv -S Cache
```
您也可以通过传入.txt文件的方式来实现多文件输入：
```bash
picker Cache.sv -f src.txt -S Cache
```
其中`src.txt`的内容为:
```
CacheStage.sv
CacheMeta.sv
```
需要注意的是，使用多文件输入时仍需要指定待测顶层模块所在的文件，例如上文中所示的`Cache.sv`。