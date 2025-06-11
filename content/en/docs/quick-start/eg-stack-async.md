---
Title:  "Case 4: Dual-Port Stack (Coroutines)"
Description:  The dual-port stack is a stack with two ports, each supporting push and pop operations. This case study uses the dual-port stack as an example to demonstrate how to drive a DUT using coroutines.
Categories:  [Example Projects, Tutorials]
Tags:  [examples, docs]
Weight:  6

---


## Introduction to the Dual-Port Stack and Environment Setup
The dual-port stack used in this case is identical to the one implemented in Case 3. Please refer to the [Introduction to the Dual-Port Stack](https://chatgpt.com/eg-stack-callback#%E5%8F%8C%E7%AB%AF%E5%8F%A3%E6%A0%88%E7%AE%80%E4%BB%8B)  and [Driver Environment Setup](https://chatgpt.com/eg-stack-callback#%E6%9E%84%E5%BB%BA%E9%A9%B1%E5%8A%A8%E7%8E%AF%E5%A2%83)  in Case 3 for more details.
## Driving the DUT Using Coroutines

In Case 3, we used callbacks to drive the DUT. While callbacks offer a way to perform parallel operations, they break the execution flow into multiple function calls and require maintaining a large amount of intermediate state, making the code more complex to write and debug.

In this case, we will introduce a method of driving the DUT using coroutines. This method not only allows for parallel operations but also avoids the issues associated with callbacks.

### Introduction to Coroutines

Coroutines are a form of "lightweight" threading that enables behavior similar to concurrent execution without the overhead of traditional threads. Coroutines operate on a single-threaded event loop, where multiple coroutines can be defined and added to the event loop, with the event loop managing their scheduling.

Typically, a defined coroutine will continue to execute until it encounters an event that requires waiting. At this point, the event loop pauses the coroutine and schedules other coroutines to run. Once the event occurs, the event loop resumes the paused coroutine to continue execution.

For parallel execution in hardware verification, this behavior is precisely what we need. We can create multiple coroutines to handle various verification tasks. We can treat the clock execution as an event, and within each coroutine, wait for this event. When the clock signal arrives, the event loop wakes up all the waiting coroutines, allowing them to continue executing until they wait for the next clock signal.
We use Python's `asyncio` to implement coroutine support:

```python
import asyncio
from dual_port_stack import *

async def my_coro(dut, name):
    for i in range(10):
        print(f"{name}: {i}")
        await dut.AStep(1)

async def test_dut(dut):
    asyncio.create_task(my_coro(dut, "coroutine 1"))
    asyncio.create_task(my_coro(dut, "coroutine 2"))
    await asyncio.create_task(dut.RunStep(10))

dut = DUTdual_port_stack()
dut.InitClock("clk")
asyncio.run(test_dut(dut))
dut.Finish()
```
You can run the above code directly to observe the execution of coroutines. In the code, we use `create_task` to create two coroutine tasks and add them to the event loop. Each coroutine task continuously prints a number and waits for the next clock signal.We use `dut.RunStep(10)` to create a background clock, which continuously generates clock synchronization signals, allowing other coroutines to continue execution when the clock signal arrives.
### Driving the Dual-Port Stack with Coroutines

Using coroutines, we can write the logic for driving each port of the dual-port stack as an independent execution flow without needing to maintain a large amount of intermediate state.

Below is a simple verification code using coroutines:


```python
import asyncio
import random
from dual_port_stack import *
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
        await self.dut.AStep(1)

        await self.dut.ACondition(lambda: self.port_dict["in_ready"].value == 1)
        self.port_dict["in_valid"].value = 0

        if is_push:
            self.model.commit_push(self.port_dict["in_data"].value)

    async def receive_resp(self):
        self.port_dict["out_ready"].value = 1
        await self.dut.AStep(1)

        await self.dut.ACondition(lambda: self.port_dict["out_valid"].value == 1)
        self.port_dict["out_ready"].value = 0

        if self.port_dict["out_cmd"].value == self.BusCMD.POP_OKAY.value:
            self.model.commit_pop(self.port_dict["out_data"].value)

    async def exec_once(self, is_push):
        await self.send_req(is_push)
        await self.receive_resp()
        for _ in range(random.randint(0, 5)):
            await self.dut.AStep(1)

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
    await asyncio.create_task(dut.RunStep(200))

if __name__ == "__main__":
    dut = DUTdual_port_stack()
    dut.InitClock("clk")
    asyncio.run(test_stack(dut))
    dut.Finish()
```
Similar to Case 3, we define a `SinglePortDriver` class to handle the logic for driving a single port. In the `main` function, we create two instances of `SinglePortDriver`, each responsible for driving one of the two ports. We place the driving processes for both ports in the main function and add them to the event loop using `asyncio.create_task`. Finally, we use `dut.RunStep(200)` to create a background clock to drive the test.
This code implements the same test logic as in Case 3, where each port performs 10 PUSH and 10 POP operations, followed by a random delay after each operation. As you can see, using coroutines eliminates the need to maintain any intermediate state.
**SinglePortDriver Logic** In the `SinglePortDriver` class, we encapsulate a single operation into the `exec_once` function. In the `main` function, we first call `exec_once(is_push=True)` 10 times to complete the PUSH operations, and then call `exec_once(is_push=False)` 10 times to complete the POP operations.In the `exec_once` function, we first call `send_req` to send a request, then call `receive_resp` to receive the response, and finally wait for a random number of clock signals to simulate a delay.The `send_req` and `receive_resp` functions have similar logic; they set the corresponding input/output signals to the appropriate values and wait for the corresponding signals to become valid. The implementation can be written according to the execution sequence of the ports.Similarly, we use the `StackModel` class to simulate stack behavior. The `commit_push` and `commit_pop` functions simulate the PUSH and POP operations, respectively, with the POP operation comparing the data.
### Running the Test
Copy the above code into `example.py` and then execute the following commands:

```bash
cd picker_out_dual_port_stack
python3 example.py
```

You can run the test code for this case directly, and you will see output similar to the following:



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
In the output, you can see the data for each `PUSH` and `POP` operation, as well as the result of each `POP` operation. If there are no error messages in the output, it indicates that the test passed.
## Pros and Cons of Coroutine-Driven Design

Using coroutine functions, we can effectively achieve parallel operations while avoiding the issues that come with callback functions. Each independent execution flow can be fully retained as a coroutine, which greatly simplifies code writing.

However, in more complex scenarios, you may find that having many coroutines can make synchronization and timing management between them more complicated. This is especially true when you need to synchronize between two coroutines that do not directly interact with the DUT.
At this point, you'll need a set of coroutine writing standards and design patterns for verification code to help you write coroutine-based verification code more effectively. Therefore, we provide the `mlvp` library, which offers a set of design patterns for coroutine-based verification code. You can learn more about `mlvp` and how it can help you write better verification code by visiting [here](https://github.com/XS-MLVP/mlvp) .
