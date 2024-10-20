---
title: How to Write an Agent
weight: 3
---


An `Agent` in the mlvp verification environment provides a high-level encapsulation of signals within a class of `Bundles`, allowing the upper-level driver code to drive and monitor the signals in the Bundle without worrying about specific signal assignments.An `Agent` consists of **driver methods**  and **monitor methods** , where the driver methods actively drive the signals in the Bundle, and the monitor methods passively observe the signals in the Bundle.
## Initializing the Agent 
To define an `Agent`, you need to create a new class that inherits from the `Agent` class in mlvp. Here’s a simple example of defining an `Agent`:

```python
from mlvp.agent import *

class AdderAgent(Agent):
    def __init__(self, bundle):
        super().__init__(bundle.step)
        self.bundle = bundle
```
In the initialization of the `AdderAgent` class, you need to pass the Bundle that this Agent will drive and provide a clock synchronization function to the parent `Agent` class. This function will be used by the Agent to determine when to call the monitor methods. Generally, it can be set to `bundle.step`, which is the clock synchronization function in the Bundle, synchronized with the DUT's clock.
## Creating Driver Methods 
In the `Agent`, the driver method is an asynchronous function used to actively drive the signals in the Bundle. The driver function needs to parse its input parameters and assign values to the signals in the Bundle based on the parsed results, which can span multiple clock cycles. If you need to obtain signal values from the Bundle, you should write the corresponding logic in the function and return the needed data through the function's return value.Each driver method should be an asynchronous function and decorated with the `@driver_method` decorator so that the Agent can recognize it as a driver method.
Here’s a simple example of defining a driver method:


```python
from mlvp.agent import *

class AdderAgent(Agent):
    def __init__(self, bundle):
        super().__init__(bundle.step)
        self.bundle = bundle

    @driver_method()
    async def exec_add(self, a, b, cin):
        self.bundle.a.value = a
        self.bundle.b.value = b
        self.bundle.cin.value = cin
        await self.bundle.step()
        return self.bundle.sum.value, self.bundle.cout.value
```
In the `exec_add` function, we assign the incoming parameters `a`, `b`, and `cin` to the corresponding signals in the Bundle. We then wait for one clock cycle. After the clock cycle ends, we return the values of `sum` and `cout` signals from the Bundle.During the development of the driver function, you can use all the synchronization methods for waiting for clock signals introduced in [How to Use the Asynchronous Environment](https://chatgpt.com/docs/mlvp/env/start_test) , such as `ClockCycles`, `Value`, etc.
Once created, you can call this driver method in your driving code like a regular function:


```python
adder_bundle = AdderBundle()
adder_agent = AdderAgent(adder_bundle)
sum, cout = await adder_agent.exec_add(1, 2, 0)
print(sum, cout)
```
Functions marked with `@driver_method` have various features when called; this will be elaborated on when writing test cases. Additionally, these functions will handle matching against the reference model and automatically call back to return values for comparison; this will be discussed in the reference model section.
## Creating Monitor Methods 
The monitor method also needs to be an asynchronous function and should be decorated with the `@monitor_method` decorator so that the Agent can recognize it as a monitor method.
Here’s a simple example of defining a monitor method:


```python
from mlvp.agent import *

class AdderAgent(Agent):
    def __init__(self, bundle):
        super().__init__(bundle.step)
        self.bundle = bundle

    @monitor_method()
    async def monitor_sum(self):
        if self.bundle.sum.value > 0:
            return self.bundle.as_dict()
```
In the `monitor_sum` function, we use the `sum` signal in the Bundle as the object to monitor. When the value of the `sum` signal is greater than 0, we collect the default message type generated by the Bundle. The collected return value will be stored in the internal message queue.Once the `monitor_method` decorator is added, the `monitor_sum` function will be automatically called by the Agent, which will use the clock synchronization function provided during the Agent's initialization to decide when to call the monitor method. By default, the Agent will call the monitor method once in each clock cycle. If the monitor method has a return value, it will be stored in the internal message queue. If the execution of a single call to the monitor method spans multiple clock cycles, the Agent will wait until the previous call to the monitor method has finished before calling it again.
If you write a monitor method like this:


```python
@monitor_method()
async def monitor_sum(self):
    return self.bundle.as_dict()
```

This monitor method will add a message to the message queue in every cycle.
**Retrieving Monitor Messages** Since this monitor method is marked with `@monitor_method`, it will be automatically called by the Agent. If you try to directly call this function in your test case as follows, it will not execute as expected:

```python
adder_bundle = AdderBundle()
adder_agent = AdderAgent(adder_bundle)
result = await adder_agent.monitor_sum()
```

Instead, when called in the above manner, the monitor method will pop the earliest collected message from the message queue and return it. If the message queue is empty, this call will wait until there are messages in the queue before returning.

If you want to get the number of messages in the message queue, you can do so as follows:


```python
message_count = adder_agent.monitor_size("monitor_sum")
```

By creating monitor methods, you can easily add a background monitoring task that observes the signal values in the Bundle and collects messages when certain conditions are met. Once a function is marked as a monitor method, the framework will also provide it with matching against the reference model and automatic collection for comparison; this will be detailed in the reference model section.
By writing multiple driver methods and monitor methods within the Agent, you complete the entire `Agent` implementation.