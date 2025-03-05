---
title: Asynchronous Programming
description: Simplifying callbacks using asynchronous mode
categories: [Example Projects, Tutorials]
tags: [examples, docs]
weight: 2
draft: true
---

# Asynchronous Programming
### Overview
#### Why Introduce Asynchronous Programming?
> In the previous section, we learned how to use callback functions. However, when using callback functions, we may encounter callback hell. This means that if callbacks are nested too deeply, the code can become very complex and difficult to manage. Therefore, we can avoid this situation by using asynchronous (async/await) methods. Using asynchronous methods can make the code structure clearer. By using the await keyword, asynchronous operations can be executed sequentially without the need for managing the execution order through callback functions.

### Implementation Principle
> In Python's asyncio, asynchronous programming is based on the following three core concepts, which will be explained in more detail in the next section.
1. Callback Functions (Callback)
Callback functions that are pre-registered are the basis of asynchronous programming. When a task is completed, the system calls the callback function to process the result of the task. Through callback functions, the program can continue to execute other tasks while waiting for the task to be completed, improving program concurrency.
2. Event Loop
The event loop is one of the core mechanisms of asynchronous programming. It is responsible for listening to various events (such as user input, I/O operations, etc.). When an event occurs, it triggers the corresponding callback function for processing. The event loop implements non-blocking task processing by continuously polling the event queue.
3. Coroutine
Coroutines are tasks defined by users.

### Common Asynchronous Programming Frameworks and Tools
> To facilitate developers in asynchronous programming, there are many excellent frameworks and tools to choose from. Here are some common asynchronous programming frameworks and tools:

1. Asyncio
Asyncio is a powerful asynchronous programming framework in Python that provides efficient coroutine support. It can be used to write network applications, web crawlers, etc., with excellent concurrency performance.
2. Node.js
Node.js is a JavaScript runtime environment built on the Chrome V8 engine, which inherently supports non-blocking I/O operations. It is widely used in web development and excels in handling high-concurrency real-time applications.
3. RxJava
RxJava is an asynchronous programming library based on the observer pattern and iterator pattern. It provides Java developers with rich operators and combination methods, simplifying the complexity of asynchronous programming.

In Python, to use asynchronous programming, you need to use the async and await keywords.
- **async**: Used to define asynchronous functions. In asynchronous functions, asynchronous operations are typically included.
- **await**: Used to wait for asynchronous operations to complete in asynchronous functions.

Here is a simple Python code to demonstrate the usage of async and await keywords:
```python
async def my_async_function():
    print("Start async_function and wait some funcion ")
    await some_other_async_function()
    print("End of my_async_function")

```
In Python, asyncio module is commonly used for asynchronous operations. In the following example, we define a greet function that prints "Hello, " + name and "Goodbye, " + name, with a 2-second interval between the two prints. We use asyncio.create_task to create two asynchronous tasks and collect the execution results.

- asyncio.create_task(): Used to create a coroutine task and schedule it for immediate execution.
- asyncio.gather(): Waits for all coroutine tasks to complete and can collect the execution results.
- asyncio.sleep(): Waits for a period in asynchronous operations.


```python
import asyncio

# Define an asynchronous function
async def greet(name):
    print("Hello, " + name)
    await asyncio.sleep(2)  # Use asynchronous sleep function
    print("Goodbye, " + name)

# Execute the asynchronous function
async def main():
    # Create and execute tasks concurrently
    task1 = asyncio.create_task(greet("verify chip"))
    task2 = asyncio.create_task(greet("picker"))

    # Wait for all tasks to complete
    await asyncio.gather(task1, task2)

# Run the main function
if __name__ == "__main__":
    asyncio.run(main())
```
- The greet("verify chip") is executed first, printing "Hello, verify chip".
- When encountering await, it switches to execute greet("picker"), printing "Hello, picker".
- After the awaited operations are completed, both tasks output "Goodbye, verify chip" and "Goodbye, picker".

### Advantages of Asynchronous Programming
Asynchronous programming has several significant advantages:

1. Improved Response Speed
Through asynchronous programming, programs can continue to execute other tasks while waiting for a task to complete, avoiding the delay caused by task blocking. This can greatly improve the program's response speed and enhance user experience.
2. Enhanced Concurrency Performance
Asynchronous programming allows programs to handle multiple tasks simultaneously, making full use of computing resources and improving system concurrency. Especially in handling a large number of I/O-intensive tasks, asynchronous programming can better leverage its advantages and reduce resource consumption.
3. Simplified Programming Logic
Asynchronous programming can avoid writing complex multithreaded code, reducing the complexity of the program and the probability of errors. By simplifying the programming logic, developers can focus more on implementing business logic.

Therefore, asynchronous programming is widely used in the following areas:

1. Web Development
In web development, asynchronous programming is commonly used to handle tasks such as network requests and database operations. By processing these tasks asynchronously, the main thread is not blocked, ensuring the concurrent performance of the web server.
2. Parallel Computing
Asynchronous programming can help achieve parallel computing by splitting a large task into multiple smaller tasks and executing them concurrently, improving computing efficiency. This is very common in scientific computing and data processing.
3. Message Queues
Message queues are one of the classic applications of asynchronous programming. Asynchronous message queues can achieve decoupling and asynchronous communication between different systems, improving system scalability and stability.

### Asynchronous Usage in Picker
For example, in Picker, we can control the flow of code execution through cycles using the following methods:

- await clk.AStep(3): Wait for clock clk to advance 3 clock cycles. The await keyword makes the program pause execution here until the clock has advanced the specified number of clock cycles before continuing execution.
- await clk.ACondition(lambda: clk.clk == 20): It waits for the condition clk.clk == 20 to be true. Similarly, the program pauses execution here until the condition is true before continuing execution.

```python
async def test_async():
    clk = XClock(lambda a: 0)
    clk.StepRis(lambda c : print("lambda ris: ", c))
    task = create_task(clk.RunStep(30))
    print("test      AStep:", clk.clk)
    await clk.AStep(3)
    print("test ACondition:", clk.clk)
    await clk.ACondition(lambda: clk.clk == 20)
    print("test        cpm:", clk.clk)
    await task
```



### Using Asynchronous to Verify the Adder

Here we continue to use the rising edge triggered adder as an example, and we have made some minor changes to the [previous code](../callback/#test_ris_adder_with_callback), replacing the generation and waiting for clock signals with asynchronous methods provided by `picker`:

>  The `Step(i)` method of XClock will advance the clock signal by `i` clock cycles, with two main functions:
>
>  1. Generate the clock signal for `i` clock cycles.
>  2. Wait for the clock to pass through `i` cycles.
>
>  In asynchronous programming, these two functions correspond to two asynchronous methods provided by XClock:
>
>  - `RunStep(i)`：Generates the clock signal for `i` clock cycles. You need to create a task with `asyncio.create_task` and use `await` at the end of the test code to wait for its completion.
>  - `AStep(i)`：Waits for the clock to pass through `i` cycles.
>
>  If the `RunStep(i)` method completes before `AStep(i)`, the entire program will be blocked at `AStep(i)`.

#### Test Code Using Asynchronous

```python
from RisAdder import *
import random
import asyncio

# Control font colors
FONT_GREEN = "\033[0;32m"  # Green
FONT_RED = "\033[0;31m"    # Red
FONT_COLOR_RESET = "\033[0m"  # Reset color

class SimpleRisAdder:
    """
    The SimpleRisAdder class is a reference adder class,
    it simulates the expected behavior of our RisAdder
    """
    def __init__(self, width) -> None:
        self.WIDTH = width  # Bit width of the adder
        # Port definition
        self.a = 0  # Input port a
        self.b = 0  # Input port b
        self.cin = 0  # Input port cin
        self.cout = 0  # Output port cout
        self.sum = 0   # Output port sum

    def step(self, a, b, cin):
        """
        Simulate rising edge update output: first update the output with the input of the previous cycle, and then update the input
        """
        sum = self.a + self.b + self.cin
        self.cout = sum >> self.WIDTH  # Calculate carry
        self.sum = sum & ((1 << self.WIDTH) - 1)  # Calculate sum

        self.a = a  # Update input a
        self.b = b  # Update input b
        self.cin = cin  # Update input cin

# Test function to verify the output of the adder
def test_adder(clk: int, dut: DUTRisAdder, ref: SimpleRisAdder) -> None:
    # Get the input and output of the adder
    a = dut.a.value
    b = dut.b.value
    cin = dut.cin.value
    cout = dut.cout.value
    sum = dut.sum.value

    # Check if the output of the adder matches the expected
    isEqual = (cout, sum) == (ref.cout, ref.sum)

    # Output test result
    print(f"Cycle: {clk}, Input(a, b, cin) = ({a:x}, {b:x}, {cin:x})")
    print(
        FONT_GREEN + "Pass."  # Output green "Pass." if the test passes
        if isEqual
        else FONT_RED + f"MisMatch! Expect cout: {ref.cout:x}, sum: {ref.sum:x}." +
        FONT_COLOR_RESET + f"Get cout: {cout:x}, sum: {sum:x}."
    )
    assert isEqual  # Trigger an assertion exception if the test fails


# Asynchronous function for running tests
async def run_test():
    WIDTH = 32  # Set the bit width of the adder
    ref = SimpleRisAdder(WIDTH)  # Create a reference adder
    dut = DUTRisAdder()  # Create the adder under test
    # Bind the clock signal
    dut.init_clock("clk")
    # Set the dut input signal to 0
    dut.a.value = 0
    dut.b.value = 0
    dut.cin.value = 0
    task = asyncio.create_task(
        dut.runstep(114514 + 1) # Create an asynchronous task to simulate the clock signal continuously for (114514+1) cycles
    )
    await dut.astep(1)  # Wait for the clock to enter the next cycle
    dut.StepRis(test_adder, (dut, ref))  # Register the function triggered on the rising edge of the clock
    # Start testing
    for _ in range(114514):
        # Generate random inputs
        a = random.randint(0, (1 << WIDTH) - 1)
        b = random.randint(0, (1 << WIDTH) - 1)
        cin = random.randint(0, 1)
        ref.step(a, b, cin)  # Update the status of the reference adder
        dut.a.value = a  # Set the input a of the adder under test
        dut.b.value = b  # Set the input b of the adder under test
        dut.cin.value = cin  # Set the input cin of the adder under test
        await dut.astep(1)  # Wait for the clock to enter the next cycle

    await task  # Wait for the clock to finish
    dut.Finish()


if __name__ == "__main__":
    asyncio.run(run_test()) # Run the test
    pass
```
