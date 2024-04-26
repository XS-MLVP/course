---
title: 波形生成
description: 生成电路波形
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 2
---

## 使用方法

在使用 Picker 工具封装 DUT 时，使用选项`-w [wave_file]`指定需要保存的波形文件。
我们针对不同仿真器，我们支持不同的文件类型：

1. [Verilator](https://www.veripool.org/wiki/verilator)
    - `.vcd`格式的波形文件。
    - `.fst`格式的波形文件，更高效的压缩文件。
2. [VCS](https://www.synopsys.com/verification/simulation/vcs.html)
    - `.fsdb`格式的波形文件，更高效的压缩文件。

需要注意的是，如果你选择自行生成 `libDPI_____.so` 文件，那么波形文件格式不受上述约束的限制。因为波形文件是在仿真器构建 `libDPI.so` 时决定的，如果你自行生成，那么波形文件格式也需要自行用对应仿真器的配置指定。

### Python 示例

正常情况下，dut需要被**显式地声明完成任务**，以通知进行模拟器的后处理工作（写入波形、覆盖率等文件）。
在Python中，需要在完成所有测试后，**调用dut的`.finalize()`方法**以通知模拟器任务已完成，进而将文件flush到磁盘。


以[加法器](/docs/quick-start/eg-adder/)为例，以下为测试程序：

```python
from UT_Adder import *

if __name__ == "__main__":
    dut = DUTAdder()

    for i in range(10):
        dut.a.value = i * 2
        dut.b.value = int(i / 4)
        dut.Step(1)
        print(dut.sum.value, dut.cout.value)

    dut.finalize() # flush the wave file to disk
```
运行结束后即可生成指定文件名的波形文件。

### C++ 示例

在C++中，dut 的析构函数会自动调用 `dut.finalize()`，因此只需要在测试结束后 `delete dut` 即可进行后处理工作（写入波形、覆盖率等文件）。

```cpp
#include "UT_Adder.hpp"

int main()
{
    UTAdder *dut = new UTAdder("libDPIAdder.so");
    printf("Initialized UTAdder\n");

    for (int c = 0; c < 114514; c++) {
    
        auto dut_cal = [&]() {
            dut->a   = c * 2;
            dut->b   = c / 2;
            dut->cin = i.cin;
            dut->xclk.Step(1);
            o_dut.sum  = (uint64_t)dut->sum;
            o_dut.cout = (uint64_t)dut->cout;
        };

        dut_cal();
        printf("[cycle %llu] a=0x%lx, b=0x%lx, cin=0x%lx\n", dut->xclk.clk, i.a,
            i.b, i.cin);
        printf("DUT: sum=0x%lx, cout=0x%lx\n", o_dut.sum, o_dut.cout);
    }

    delete dut; // automatically call dut.finalize() in ~UTAdder()
    printf("Simulation finished\n");
    return 0;
}
```

## 查看结果

### GTKWave

使用 GTKWave 打开 `fst` 或 `vcd` 波形文件，即可查看波形图。

![GTKWave](gtkwave.jpg)

### Verdi

使用 Verdi 打开 `fsdb` 或 `vcd` 波形文件，即可查看波形图。

![Verdi](verdi.jpg)