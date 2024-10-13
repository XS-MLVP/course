---
title: How to Use an Asynchronous Environment 
weight: 1
---
## Starting the Event Loop 

In the previously described verification environment, we designed a standardized setup. However, if we attempt to write it as a simple single-threaded program, we may encounter complex implementation issues.

For instance, consider having two driver methods that drive two different interfaces. Inside each driver method, we need to wait for several clock cycles of the DUT (Device Under Test), and both methods must run simultaneously. In a basic single-threaded program, running both driver methods concurrently can be quite challenging. Even if we force concurrency using multithreading, there is still no built-in mechanism to wait for the DUT to advance through multiple clock cycles. This limitation exists because the interfaces provided by Picker allow us to push the DUT forward by one cycle at a time but not to wait for it.
Moreover, in cases where multiple components of the environment need to run concurrently, we require an environment that supports asynchronous execution. **mlvp**  uses Python's coroutines to manage asynchronous programs. It builds an event loop on top of a single thread to manage multiple concurrently running coroutines. These coroutines can wait on each other and switch between tasks via the event loop.Before starting the event loop, we need to understand two keywords, `async` and `await`, to grasp how Python manages coroutines.By adding the `async` keyword before a function, we define it as a coroutine, for example:

```python
async def my_coro():
    ...
```
Inside the coroutine, we use the `await` keyword to run another coroutine and wait for it to complete, for example:

```python
async def my_coro():
    return "my_coro"

async def my_coro2():
    result = await my_coro()
    print(result)
```
If you don't want to wait for a coroutine to finish but simply run it in the background, you can use **mlvp** 's `create_task` method, like so:

```python
import mlvp

async def my_coro():
    return "my_coro"

async def my_coro2():
    mlvp.create_task(my_coro())
```
How do we start the event loop and run `my_coro2`? In **mlvp** , we use `mlvp.run` to start the event loop and run the asynchronous program:

```python
import mlvp

mlvp.run(my_coro2())
```
Since all environment components in **mlvp**  need to run within the event loop, when starting the **mlvp**  verification environment, you must first initiate the event loop via `mlvp.run` and then create the **mlvp**  verification environment inside the loop.
Thus, the test environment should be set up as follows:


```python
import mlvp

async def start_test():
    # Create verification environment
    env = MyEnv()

    ...

mlvp.run(start_test())
```

## How to Manage DUT Clock 

As mentioned earlier, if we need two driver methods to run simultaneously and each one to wait for several DUT clock cycles, asynchronous environments allow us to wait for specific events. However, Picker only provides the ability to push the DUT forward by one cycle and does not provide an event to wait on.
**mlvp**  addresses this by creating a background clock to automatically push the DUT forward one cycle at a time. After each cycle, the background clock sends a clock signal to other coroutines, allowing them to resume execution. The actual clock cycles of the DUT are driven by the background clock, while other coroutines only need to wait for the clock signal.In **mlvp** , the background clock is created using `start_clock`:

```python
import mlvp

async def start_test():
    dut = MyDUT()
    mlvp.start_clock(dut)

mlvp.run(start_test())
```
Simply call `start_clock` within the event loop to create the background clock. It requires a DUT object to drive the DUT's execution and bind the clock signal to the DUT and its pins.In other coroutines, you can use `ClockCycles` to wait for the clock signal. The `ClockCycles` parameter can be the DUT itself or any of its pins. For example:

```python
import mlvp
from mlvp.triggers import *

async def my_coro(dut):
    await ClockCycles(dut, 10)
    print("10 cycles passed")

async def start_test():
    dut = MyDUT()
    mlvp.start_clock(dut)

    await my_coro(dut)

mlvp.run(start_test())
```
In `my_coro`, `ClockCycles` is used to wait for 10 clock cycles of the DUT. After 10 cycles, `my_coro` continues executing and prints "10 cycles passed."**mlvp**  provides several methods for waiting on clock signals, such as: 
- `ClockCycles`: Wait for a specified number of DUT clock cycles.
 
- `Value`: Wait for a DUT pin to equal a specific value.
 
- `AllValid`: Wait for all DUT pins to be valid simultaneously.
 
- `Condition`: Wait for a condition to be met.
 
- `Change`: Wait for a change in the value of a DUT pin.
 
- `RisingEdge`: Wait for the rising edge of a DUT pin.
 
- `FallingEdge`: Wait for the falling edge of a DUT pin.

For more methods of waiting on clock signals, refer to the API documentation.