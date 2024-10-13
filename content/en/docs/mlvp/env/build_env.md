---
title: How to Build an Env
weight: 4
---

`Env` is used in the mlvp verification environment to package the entire verification setup. It directly instantiates all the agents needed in the verification environment and is responsible for passing the required bundles to these agents.
Once the Env is created, the specification for writing reference models is also determined. Reference models written according to this specification can be directly attached to the Env, allowing it to handle automatic synchronization of the reference models.

## Creating an Env 
To define an `Env`, you need to create a new class that inherits from the `Env` class in mlvp. Here’s a simple example of defining an `Env`:

```python
from mlvp.env import *

class DualPortStackEnv(Env):
    def __init__(self, port1_bundle, port2_bundle):
        super().__init__()

        self.port1_agent = StackAgent(port1_bundle)
        self.port2_agent = StackAgent(port2_bundle)
```
In this example, we define a `DualPortStackEnv` class that instantiates two identical `StackAgent` objects, each responsible for driving different Bundles.
You can choose to connect the Bundles outside the Env or within the Env itself, as long as you ensure that the correct Bundles are passed to the Agents.

At this point, if you do not need to write additional reference models, the entire verification environment setup is complete, and you can directly write test cases using the interfaces provided by the Env. For example:


```python
port1_bundle = StackPortBundle()
port2_bundle = StackPortBundle()
env = DualPortStackEnv(port1_bundle, port2_bundle)

await env.port1_agent.push(1)
await env.port2_agent.push(1)
print(await env.port1_agent.pop())
print(await env.port2_agent.pop())
```

## Attaching Reference Models 

Once the Env is defined, the interfaces for the entire verification environment are also established, for example:


```perl
DualPortStackEnv
  - port1_agent
    - @driver_method push
    - @driver_method pop
    - @monitor_method some_monitor
  - port2_agent
    - @driver_method push
    - @driver_method pop
    - @monitor_method some_monitor
```

Reference models written according to this specification can be directly attached to the Env, allowing it to automatically synchronize the reference models. This can be done as follows:


```python
env = DualPortStackEnv(port1_bundle, port2_bundle)
env.attach(StackRefModel())
```

An Env can attach multiple reference models, all of which will be automatically synchronized by the Env.

The specific method for writing reference models will be detailed in the section on writing reference models.