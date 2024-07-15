---
title: 案例二：随机数生成器
description: 基于一个16bit的LFSR随机数生成器展示工具的用法，该随机数生成器内部存在时钟信号、时序逻辑与寄存器。
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 4
---

## RTL源码

在本案例中，我们驱动一个随机数生成器，其源码如下：

```verilog
module RandomGenerator (
    input wire clk,
    input wire reset,
    input [15:0] seed,
    output [15:0] random_number
);
    reg [15:0] lfsr;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            lfsr <= seed;
        end else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[14]};
        end
    end
 
    assign random_number = lfsr;
endmodule
```

该随机数生成器包含一个 16 位的 LFSR，其输入为一个 16 位的种子数，输出为一个 16 位的随机数。LFSR 的更新规则为：
1. 将当前的 LFSR 的最高位与次高位异或，称为new_bit。 
2. 将原来的 LFSR 向左平移一位，将 new_bit 放在最低位。
2. 丢弃最高位。


## 测试过程

在测试过程中，我们将创建一个名为 RandomGenerator 的文件夹，其中包含一个 RandomGenerator.v 文件。该文件内容即为上述的 RTL 源码。

### 将RTL构建为 Python Module

#### 生成中间文件

进入 RandomGenerator 文件夹，执行如下命令：

```bash
picker export --autobuild=false RandomGenerator.v -w RandomGenerator.fst --sname RandomGenerator --tdir picker_out_rmg --lang python -e --sim verilator
```

该命令的含义是：

1. 将RandomGenerator.v作为 Top 文件，并将RandomGenerator作为 Top Module，基于 verilator 仿真器生成动态库，生成目标语言为 Python。
2. 启用波形输出，目标波形文件为RandomGenerator.fst
3. 包含用于驱动示例项目的文件(-e)，同时codegen完成后不自动编译(-autobuild=false)。
4. 最终的文件输出路径是 picker_out_rmg


输出的目录类似[加法器验证-生成中间文件](/docs/quick-start/eg-adder/#生成中间文件)，这里不再赘述。

#### 构建中间文件

进入 `picker_out_rmg` 目录并执行 make 命令，即可生成最终的文件。

> 备注：其编译过程类似于 [加法器验证-编译流程](/docs/quick-start/eg-adder/#构建中间文件)，这里不再赘述。

最终目录结果为：

```shell
picker_out_rmg
|-- RandomGenerator.fst # 测试的波形文件
|-- UT_RandomGenerator
|   |-- RandomGenerator.fst.hier
|   |-- _UT_RandomGenerator.so # Swig生成的wrapper动态库
|   |-- __init__.py  # Python Module的初始化文件，也是库的定义文件
|   |-- libDPIRandomGenerator.a # 仿真器生成的库文件
|   |-- libUTRandomGenerator.so # 基于dut_base生成的libDPI动态库封装
|   `-- libUT_RandomGenerator.py # Swig生成的Python Module
|   `-- xspcomm  # xspcomm基础库，固定文件夹，不需要关注
`-- example.py # 示例代码
```

### 配置测试代码

> 复制以下代码替换 `example.py` 中的内容。

```python
from UT_RandomGenerator import *
import random

# 定义参考模型
class LFSR_16:
    def __init__(self, seed):
        self.state = seed & ((1 << 16) - 1)

    def Step(self):
        new_bit = (self.state >> 15) ^ (self.state >> 14) & 1
        self.state = ((self.state << 1) | new_bit ) & ((1 << 16) - 1)

if __name__ == "__main__":
    dut = DUTRandomGenerator()            # 创建DUT 
    dut.InitClock("clk")                  # 指定时钟引脚，初始化时钟
    seed = random.randint(0, 2**16 - 1)   # 生成随机种子
    dut.seed.value = seed                 # 设置DUT种子
    ref = LFSR_16(seed)                   # 创建参考模型用于对比

    # reset DUT
    dut.reset.value = 1                   # reset 信号置1
    dut.Step()                            # 推进一个时钟周期（DUTRandomGenerator是时序电路，需要通过Step推进）
    dut.reset.value = 0                   # reset 信号置0
    dut.Step()                            # 推进一个时钟周期

    for i in range(65536):                # 循环65536次
        dut.Step()                        # dut 推进一个时钟周期，生成随机数
        ref.Step()                        # ref 推进一个时钟周期，生成随机数
        assert dut.random_number.value == ref.state, "Mismatch"  # 对比DUT和参考模型生成的随机数
        print(f"Cycle {i}, DUT: {dut.random_number.value:x}, REF: {ref.state:x}") # 打印结果
    # 完成测试
    print("Test Passed")
    dut.Finish()    # Finish函数会完成波形、覆盖率等文件的写入
```

### 运行测试程序

在 `picker_out_rmg` 目录下执行 `python example.py` 即可运行测试程序。在运行完成后，若输出 `Test Passed`，则表示测试通过。完成运行后，会生成波形文件：RandomGenerator.fst，可在bash中通过以下命令进行查看。

>gtkwave RandomGenerator.fst

输出示例：

```shell
···
Cycle 65529, DUT: d9ea, REF: d9ea
Cycle 65530, DUT: b3d4, REF: b3d4
Cycle 65531, DUT: 67a9, REF: 67a9
Cycle 65532, DUT: cf53, REF: cf53
Cycle 65533, DUT: 9ea6, REF: 9ea6
Cycle 65534, DUT: 3d4d, REF: 3d4d
Cycle 65535, DUT: 7a9a, REF: 7a9a
Test Passed, destroy UT_RandomGenerator
```
