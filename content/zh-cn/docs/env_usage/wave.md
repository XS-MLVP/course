---
title: 波形生成
description: 生成电路波形
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 2
---

在使用Picker工具生成DUT时，使用选项`-w [wave_file]`指定预保存的波形文件，其文件格式为`.vcd`或者`.fst`。需要注意的是使用verilator作为仿真器时，只支持`.vcd`格式的波形文件。

## Python
在测试结束后，调用dut的`.finalize()`方法即可生成波形。以[驱动加法器]("/zh-cn/docs/quick-start/eg-adder")为例，以下为测试程序：
```python
from UT_Adder import *

if __name__ == "__main__":
    dut = DUTAdder()
    # dut.init_clock("clk")

    for i in range(6):
        dut.a.value = i * 2
        dut.b.value = i / 4
        dut.Step(1)
        print(dut.sum.value, dut.cout.value)

    dut.finalize()
```
运行结束后即可生成指定文件名的波形文件。

## C++
同样的，使用C++作为测试程序语言时，最后只需要`delete dut`即可生成波形。具体可以参考[驱动加法器]("/zh-cn/docs/quick-start/eg-adder")章节。
