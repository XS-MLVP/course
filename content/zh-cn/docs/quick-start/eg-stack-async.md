---
title: 案例四：双端口栈——基于协程的驱动
description: 双端口栈是一个拥有两个端口的栈，每个端口都支持push和pop操作。本案例以双端口栈为例，展示如何使用协程驱动DUT
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 6
---

## 双端口栈简介

双端口栈是一种数据结构，支持两个端口同时进行操作。与传统单端口栈相比，双端口栈允许同时进行数据的读写操作，在例如多线程并发读写等场景下，双端口栈能够提供更好的性能。本例中，我们提供了一个简易的双端口栈实现，其源码如下：

```verilog
module dual_port_stack (
    input clk,
    input rst,

    // Interface 0
    input in0_valid,
    output in0_ready,
    input [7:0] in0_data,
    input [1:0] in0_cmd,
    output out0_valid,
    input out0_ready,
    output [7:0] out0_data,
    output [1:0] out0_cmd,

    // Interface 1
    input in1_valid,
    output in1_ready,
    input [7:0] in1_data,
    input [1:0] in1_cmd,
    output out1_valid,
    input out1_ready,
    output [7:0] out1_data,
    output [1:0] out1_cmd
);
    // Command definitions
    localparam CMD_PUSH = 2'b00;
    localparam CMD_POP = 2'b01;
    localparam CMD_PUSH_OKAY = 2'b10;
    localparam CMD_POP_OKAY = 2'b11;

    // Stack memory and pointer
    reg [7:0] stack_mem[0:255];
    reg [7:0] sp;
    reg busy;

    reg [7:0] out0_data_reg, out1_data_reg;
    reg [1:0] out0_cmd_reg, out1_cmd_reg;
    reg out0_valid_reg, out1_valid_reg;

    assign out0_data = out0_data_reg;
    assign out0_cmd = out0_cmd_reg;
    assign out0_valid = out0_valid_reg;
    assign out1_data = out1_data_reg;
    assign out1_cmd = out1_cmd_reg;
    assign out1_valid = out1_valid_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sp <= 0;
            busy <= 0;
        end else begin
            // Interface 0 Request Handling
            if (!busy && in0_valid && in0_ready) begin
                case (in0_cmd)
                    CMD_PUSH: begin
                        busy <= 1;
                        sp <= sp + 1;
                        out0_valid_reg <= 1;
                        stack_mem[sp] <= in0_data;
                        out0_cmd_reg <= CMD_PUSH_OKAY;
                    end
                    CMD_POP: begin
                        busy <= 1;
                        sp <= sp - 1;
                        out0_valid_reg <= 1;
                        out0_data_reg <= stack_mem[sp - 1];
                        out0_cmd_reg <= CMD_POP_OKAY;
                    end
                    default: begin
                        out0_valid_reg <= 0;
                    end
                endcase
            end

            // Interface 1 Request Handling
            if (!busy && in1_valid && in1_ready) begin
                case (in1_cmd)
                    CMD_PUSH: begin
                        busy <= 1;
                        sp <= sp + 1;
                        out1_valid_reg <= 1;
                        stack_mem[sp] <= in1_data;
                        out1_cmd_reg <= CMD_PUSH_OKAY;
                    end
                    CMD_POP: begin
                        busy <= 1;
                        sp <= sp - 1;
                        out1_valid_reg <= 1;
                        out1_data_reg <= stack_mem[sp - 1];
                        out1_cmd_reg <= CMD_POP_OKAY;
                    end
                    default: begin
                        out1_valid_reg <= 0;
                    end
                endcase
            end

            // Interface 0 Response Handling
            if (busy && out0_ready) begin
                out0_valid_reg <= 0;
                busy <= 0;
            end

            // Interface 1 Response Handling
            if (busy && out1_ready) begin
                out1_valid_reg <= 0;
                busy <= 0;
            end
        end
    end

    assign in0_ready = (in0_cmd == CMD_PUSH && sp < 255|| in0_cmd == CMD_POP && sp > 0) && !busy;
    assign in1_ready = (in1_cmd == CMD_PUSH && sp < 255|| in1_cmd == CMD_POP && sp > 0) && !busy && !(in0_ready && in0_valid);

endmodule
```

在该实现中，除了时钟信号(clk)和复位信号(rst)之外，还包含了两个端口的输入输出信号，它们拥有相同的接口定义。每个端口的信号含义如下：

- 请求端口（in）
  - `in_valid` 输入数据有效信号
  - `in_ready` 输入数据准备好信号
  - `in_data` 输入数据
  - `in_cmd` 输入命令 （0:PUSH, 1:POP）
- 响应端口（out）
  - `out_valid` 输出数据有效信号
  - `out_ready` 输出数据准备好信号
  - `out_data` 输出数据
  - `out_cmd` 输出命令 （2:PUSH_OKAY, 3:POP_OKAY）

当我们想通过一个端口对栈进行一次操作时，首先需要将需要的数据和命令写入到输入端口，然后等待输出端口返回结果。

具体地，如果我们想对栈进行一次 PUSH 操作。首先我们应该将需要 PUSH 的数据写入到 `in_data` 中，然后将 `in_cmd` 设置为 0，表示 PUSH 操作，并将 `in_valid` 置为 1，表示输入数据有效。接着，我们需要等待 `in_ready` 为 1，保证数据已经正确的被接收，此时 PUSH 请求已经被正确发送。

命令发送成功后，我们需要在响应端口等待栈的响应信息。当 `out_valid` 为 1 时，表示栈已经完成了对应的操作，此时我们可以从 `out_data` 中读取栈的返回数据（POP 操作的返回数据将会放置于此），从 `out_cmd` 中读取栈的返回命令。当读取到数据后，需要将 `out_ready` 置为 1，以通知栈正确接收到了返回信息。

如果两个端口的请求同时有效时，栈将会优先处理端口 0 的请求。


## 构建驱动环境

与案例一和案例二类似，在对双端口栈进行测试之前，我们首先需要利用 Picker 工具将 RTL 代码构建为 Python Module。在构建完成后，我们将通过 Python 脚本驱动 RTL 代码进行测试。

首先，创建名为 `dual_port_stack.v` 的文件，并将上述的 RTL 代码复制到该文件中，接着在相同文件夹下执行以下命令：

```bash
picker export --autobuild=true dual_port_stack.v -w dual_port_stack.fst --sname dual_port_stack --tdir picker_out_dual_port_stack --lang python -e --sim verilator
```

生成好的驱动环境位于 `picker_out_dual_port_stack` 文件夹中, 其中 `UT_dual_port_stack` 为生成的 Python Module，`example.py` 为测试脚本。

可以通过以下命令运行测试脚本：

```bash
cd picker_out_dual_port_stack
python3 example.py
```

若运行过程中无错误发生，则代表环境被正确构建。

## 利用协程驱动 DUT

在案例三中，我们使用了回调函数的方式来驱动DUT，回调函数虽然给我们提供了一种能够完成并行操作的方式，然而其却把完成的执行流程割裂为多次函数调用，并需要维护大量中间状态，导致代码的编写及调试变得较为复杂。

在本案例中，我们将会介绍一种通过协程驱动的方法，这种方法不仅能够做到并行操作，同时能够很好地避免回调函数所带来的问题。

### 协程简介

协程是一种“轻量级”的线程，通过协程，你可以实现与线程相似的并发执行的行为，但其开销却远小于线程。其实现原理是，协程库实现了一个运行于单线程之上的事件循环（EventLoop），程序员可以定义若干协程并且加入到事件循环，由事件循环负责这些协程的调度。

一般来说，我们定义的协程在执行过程中会持续执行，直到遇到一个需要等待的“事件”，此时事件循环就会暂停执行该协程，并调度其他协程运行。当事件发生后，事件循环会再次唤醒该协程，继续执行。

对于硬件验证中的并行执行来说，这种特性正是我们所需要的，我们可以创建多个协程，来完成验证中的多个驱动任务。我们可以将时钟的执行当做事件，在每个协程中等待这个事件，当时钟信号到来时，事件循环会唤醒所有等待的协程，使其继续执行，直到他们等待下一个时钟信号。

我们用 Python 中的 `asyncio` 来实现对协程的支持：

```python
import asyncio
from UT_dual_port_stack import *

async def my_coro(dut, name):
    for i in range(10):
        print(f"{name}: {i}")
        await dut.astep(1)

async def test_dut(dut):
    asyncio.create_task(my_coro(dut, "coroutine 1"))
    asyncio.create_task(my_coro(dut, "coroutine 2"))
    await asyncio.create_task(dut.runstep(10))

dut = DUTdual_port_stack()
dut.init_clock("clk")
asyncio.run(test_dut(dut))
dut.finalize()
```

你可以直接运行上述代码来观察协程的执行过程。在上述代码中我们用 `create_task` 创建了两个协程任务并加入到事件循环中，每个协程任务中，会不断打印一个数字并等待下一个时钟信号到来。

我们使用 `dut.runstep(10)` 来创建一个后台时钟，它会不断产生时钟同步信号，使得其他协程能够在时钟信号到来时继续执行。

### 基于协程驱动的双端口栈

利用协程，我们就可以将驱动双端口栈中单个端口逻辑写成一个独立的执行流，不需要再去维护大量的中间状态。

下面是我们提供的一个简单的使用协程驱动的验证代码：

```python
import asyncio
import random
from UT_dual_port_stack import *
from enum import Enum

class StackModel:
    def __init__(self):
        self.stack = []

    def commit_push(self, data):
        self.stack.append(data)
        print("Push", data)

    def commit_pop(self, dut_data):
        print("Pop", dut_data)
        model_data = self.stack.pop()
        assert model_data == dut_data, f"The model data {model_data} is not equal to the dut data {dut_data}"
        print(f"Pass: {model_data} == {dut_data}")

class SinglePortDriver:
    class BusCMD(Enum):
        PUSH = 0
        POP = 1
        PUSH_OKAY = 2
        POP_OKAY = 3

    def __init__(self, dut, model: StackModel, port_dict):
        self.dut = dut
        self.model = model
        self.port_dict = port_dict

    async def send_req(self, is_push):
        self.port_dict["in_valid"].value = 1
        self.port_dict["in_cmd"].value = self.BusCMD.PUSH.value if is_push else self.BusCMD.POP.value
        self.port_dict["in_data"].value = random.randint(0, 2**8-1)

        await self.dut.astep(1)
        while self.port_dict["in_ready"].value != 1:
            await self.dut.astep(1)
        self.port_dict["in_valid"].value = 0

        if is_push:
            self.model.commit_push(self.port_dict["in_data"].value)

    async def receive_resp(self):
        self.port_dict["out_ready"].value = 1
        await self.dut.astep(1)
        while self.port_dict["out_valid"].value != 1:
            await self.dut.astep(1)
        self.port_dict["out_ready"].value = 0

        if self.port_dict["out_cmd"].value == self.BusCMD.POP_OKAY.value:
            self.model.commit_pop(self.port_dict["out_data"].value)

    async def exec_once(self, is_push):
        await self.send_req(is_push)
        await self.receive_resp()
        for _ in range(random.randint(0, 5)):
            await self.dut.astep(1)

    async def main(self):
        for _ in range(10):
            await self.exec_once(is_push=True)
        for _ in range(10):
            await self.exec_once(is_push=False)

async def test_stack(stack):
    model = StackModel()

    port0 = SinglePortDriver(stack, model, {
        "in_valid": stack.in0_valid,
        "in_ready": stack.in0_ready,
        "in_data": stack.in0_data,
        "in_cmd": stack.in0_cmd,
        "out_valid": stack.out0_valid,
        "out_ready": stack.out0_ready,
        "out_data": stack.out0_data,
        "out_cmd": stack.out0_cmd,
    })

    port1 = SinglePortDriver(stack, model, {
        "in_valid": stack.in1_valid,
        "in_ready": stack.in1_ready,
        "in_data": stack.in1_data,
        "in_cmd": stack.in1_cmd,
        "out_valid": stack.out1_valid,
        "out_ready": stack.out1_ready,
        "out_data": stack.out1_data,
        "out_cmd": stack.out1_cmd,
    })

    asyncio.create_task(port0.main())
    asyncio.create_task(port1.main())
    await asyncio.create_task(dut.runstep(200))

if __name__ == "__main__":
    dut = DUTdual_port_stack()
    dut.init_clock("clk")
    asyncio.run(test_stack(dut))
    dut.finalize()
```

与案例三类似，我们定义了一个 `SinglePortDriver` 类，用于驱动单个端口的逻辑。在 `main` 函数中，我们创建了两个 `SinglePortDriver` 实例，分别用于驱动两个端口。我们将两个端口的驱动过程放在了入口函数 `main` 中，并通过 `asyncio.create_task` 将其加入到事件循环中，在最后我们通过 `dut.runstep(200)` 来创建了后台时钟，以推动测试的进行。

该代码实现了与案例三一致的测试逻辑，即在每个端口中对栈进行 10 次 PUSH 和 10 次 POP 操作，并在操作完成后添加随机延迟。但你可以清晰的看到，利用协程进行编写，不需要维护任何的中间状态。

**SinglePortDriver 逻辑**

在 `SinglePortDriver` 类中，我们将一次操作封装为 `exec_once` 这一个函数，在 `main` 函数中只需要首先调用 10 次 `exec_once(is_push=True)` 来完成 PUSH 操作，再调用 10 次 `exec_once(is_push=False)` 来完成 POP 操作即可。

在 `exec_once` 函数中，我们首先调用 `send_req` 函数来发送请求，然后调用 `receive_resp` 函数来接收响应，最后通过等待随机次数的时钟信号来模拟延迟。

`send_req` 和 `receive_resp` 函数的实现逻辑类似，只需要将对应的输入输出信号设置为对应的值，然后等待对应的信号变为有效即可，可以完全根据端口的执行顺序来编写。

类似地，我们使用 `StackModel` 类来模拟栈的行为，在 `commit_push` 和 `commit_pop` 函数中分别模拟了 PUSH 和 POP 操作，并在 POP 操作中进行了数据的比较。

### 运行测试

将上述代码复制到 `example.py` 中，然后执行以下命令：

```bash
cd picker_out_dual_port_stack
python3 example.py
```

可直接运行本案例的测试代码，你将会看到类似如下的输出：

```shell
...
Push 141
Push 102
Push 63
Push 172
Push 208
Push 130
Push 151
...
Pop 102
Pass: 102 == 102
Pop 138
Pass: 138 == 138
Pop 56
Pass: 56 == 56
Pop 153
Pass: 153 == 153
Pop 129
Pass: 129 == 129
Pop 235
Pass: 235 == 235
Pop 151
...
```

在输出中，你可以看到每次 `PUSH` 和 `POP` 操作的数据，以及每次 `POP` 操作的结果。如果输出中没有错误信息，则表示测试通过。

## 协程驱动的优劣

通过协程函数，我们可以很好地实现并行操作，同时避免了回调函数所带来的问题。每个独立的执行流都能被完整保留，实现为一个协程，大大方便了代码的编写。

然而，在更为复杂的场景下你会发现，实现了众多协程，会使得协程之间的同步和时序管理变得复杂。尤其是你需要在两个不与DUT直接交互的协程之间进行同步时，这种现象会尤为明显。

在这时候，你就需要一套协程编写的规范以及验证代码的设计模式，来帮助你更好地编写基于协程的验证代码。因此，我们提供了 mlvp 库，它提供了一套基于协程的验证代码设计模式，你可以通过使用 mlvp 来更好地编写验证代码，你可以在[这里](https://github.com/XS-MLVP/mlvp)去进一步了解 mlvp。
