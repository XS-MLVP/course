---
title: How to Drive Using Test Environment Interfaces
weight: 1
---

## How to Simultaneously Call Multiple Driver Functions 

Once the verification environment is set up, you can write test cases using the interfaces provided by the verification environment. However, it is often difficult to call two driver functions simultaneously using conventional serial code. This becomes especially important when multiple interfaces need to be driven at the same time, and mlvp provides a simple way to handle such scenarios.

### Simultaneously Calling Multiple Driver Functions of Different Categories 

For example, suppose the current Env structure is as follows:


```perl
DualPortStackEnv
  - port1_agent
    - @driver_method push
    - @driver_method pop
  - port2_agent
    - @driver_method push
    - @driver_method pop
```
We want to call the `push` functions of both `port1_agent` and `port2_agent` simultaneously in a test case, to drive both interfaces at the same time.In mlvp, this can be achieved using the `Executor`.

```python
from mlvp import Executor

def test_push(env):
    async with Executor() as exec:
        exec(env.port1_agent.push(1))
        exec(env.port2_agent.push(2))

    print("result", exec.get_results())
```
We use `async with` to create an `Executor` object and establish an execution block. By directly calling `exec`, you can add the driver functions that need to be executed. When the `Executor` object exits the scope, all added driver functions will be executed simultaneously. The `Executor` will automatically wait for all the driver functions to complete.If you need to retrieve the return values of the driver functions, you can use the `get_results` method. `get_results` returns a dictionary where the keys are the names of the driver functions, and the values are lists containing the return values of the respective driver functions.
### Multiple Calls to the Same Driver Function 
If the same driver function is called multiple times in the execution block, `Executor` will automatically serialize these calls.

```python
from mlvp import Executor

def test_push(env):
    async with Executor() as exec:
        for i in range(5):
            exec(env.port1_agent.push(1))
        exec(env.port2_agent.push(2))

    print("result", exec.get_results())
```
In the code above, `port1_agent.push` will be called 5 times, and `port2_agent.push` will be called once. Since `port1_agent.push` is the same driver function, `Executor` will automatically serialize these 5 calls, and the return values will be stored sequentially in the result list. Meanwhile, `port2_agent.push` will execute in parallel with the serialized `port1_agent.push` calls.
In this process, we created a scheduling process like this:


```sql
------------------  current time --------------------
  +---------------------+   +---------------------+
  | group "agent1.push" |   | group "agent2.push" |
  | +-----------------+ |   | +-----------------+ |
  | |   agent1.push   | |   | |   agent2.push   | |
  | +-----------------+ |   | +-----------------+ |
  | +-----------------+ |   +---------------------+
  | |   agent1.push   | |
  | +-----------------+ |
  | +-----------------+ |
  | |   agent1.push   | |
  | +-----------------+ |
  | +-----------------+ |
  | |   agent1.push   | |
  | +-----------------+ |
  | +-----------------+ |
  | |   agent1.push   | |
  | +-----------------+ |
  +---------------------+
------------------- Executor exit -------------------
```
`Executor` automatically created two scheduling groups based on the function names of the driver functions, and the driver functions were added to their respective groups in the order they were called. Inside the scheduling group, the driver functions are executed sequentially. Across groups, driver functions are executed in parallel.The default name for the scheduling group is the driver function’s path name, separated by periods (`.`).Using the `sche_group` parameter, you can manually specify which scheduling group a driver function call belongs to. For example:

```python
from mlvp import Executor

def test_push(env):
    async with Executor() as exec:
        for i in range(5):
            exec(env.port1_agent.push(1), sche_group="group1")
        exec(env.port2_agent.push(2), sche_group="group1")

    print("result", exec.get_results())
```
In this case, `port1_agent.push` and `port2_agent.push` will be added sequentially to the same scheduling group, `group1`, and they will execute in series. In the dictionary returned by `get_results`, `group1` will be the key, and its value will be a list of the return values for all the driver functions in `group1`.
### Adding Custom Functions to the Executor 
If we call driver functions or other functions from a custom function and wish to schedule the custom function through the `Executor`, we can add the custom function in the same way as we add driver functions.

```python
from mlvp import Executor

async def multi_push_port1(env, times):
    for i in range(times):
        await env.port1_agent.push(1)

async def test_push(env):
    async with Executor() as exec:
        for i in range(2):
            exec(multi_push_port1(env, 5))
        exec(env.port2_agent.push(2))

    print("result", exec.get_results())
```
Here, `multi_push_port1` will be added to the `Executor`, creating a scheduling group named `multi_push_port1` and adding two calls to it. This will execute in parallel with the `port2_agent.push` group.We can also use `Executor` within custom functions, or call other custom functions, allowing us to create arbitrarily complex scheduling scenarios with `Executor`.
### Example Scenarios: 
**Scenario 1** :
The environment interface is as follows:


```perl
Env
- agent1
    - @driver_method send
- agent2
    - @driver_method send
```
The `send` function in both agents needs to be called 5 times in parallel, sending the result of the previous call each time, with the first call sending `0`. The two function calls are independent of each other.

```python
from mlvp import Executor

async def send(agent):
    result = 0
    for i in range(5):
        result = await agent.send(result)

async def test_send(env):
    async with Executor() as exec:
        exec(send(env.agent1), sche_group="agent1")
        exec(send(env.agent2), sche_group="agent2")

    print("result", exec.get_results())
```
**Scenario 2** :
The environment interface is as follows:


```markdown
env
- agent1
    - @driver_method long_task
- agent2
    - @driver_method task1
    - @driver_method task2
```
`task1` and `task2` need to be executed in parallel, with synchronization after each call. Both need to be called 5 times, and `long_task` needs to execute in parallel with `task1` and `task2`.

```python
from mlvp import Executor

async def exec_once(env):
    async with Executor() as exec:
        exec(env.agent2.task1())
        exec(env.agent2.task2())

async def test_case(env):
    async with Executor() as exec:
        for i in range(5):
            exec(exec_once(env))
        exec(env.agent1.long_task())

    print("result", exec.get_results())
```

### Setting Executor Exit Conditions 
The `Executor` will wait for all driver functions to complete before exiting, but sometimes it’s unnecessary to wait for all functions. You can set the exit condition using the `exit` parameter when creating the `Executor`.The `exit` parameter can be set to `all`, `any`, or `none`, which correspond to exiting after all groups finish, after any group finishes, or immediately without waiting.

```python
from mlvp import Executor

async def send_forever(agent):
    result = 0
    while True:
        result = await agent.send(result)

async def test_send(env):
    async with Executor(exit="any") as exec:
        exec(send_forever(env.agent1))
        exec(env.agent2.send(1))

    print("result", exec.get_results())
```
In this code, the `send_forever` function runs in an infinite loop. By setting `exit="any"`, the `Executor` will exit after `env.agent2.send` completes, without waiting for `send_forever`.If needed later, you can wait for all tasks to complete by calling `exec.wait_all`.
