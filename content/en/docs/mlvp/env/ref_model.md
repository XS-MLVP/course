---
title: How to Write a Reference Model
weight: 5
---

A `reference model` is used to simulate the behavior of the design under verification, aiding in the validation process. In the mlvp verification environment, the reference model needs to follow the `Env` interface specifications so it can be attached to `Env`, allowing automatic synchronization by `Env`.
## Two Ways to Implement a Reference Model 
mlvp provides two methods for implementing a reference model, both of which can be attached to `Env` for automatic synchronization. Depending on the scenario, you can choose the most suitable method for your reference model implementation.These two methods are **function call mode**  and **independent execution flow mode** . Below, we will introduce both concepts in detail.
### Function Call Mode 
**Function call mode**  defines the reference model's external interface as a series of functions, driving the reference model's behavior by calling these functions. In this mode, data is passed to the reference model through input parameters, and the model's output data is retrieved through return values. The internal state of the reference model is updated through the logic within the function body.
Here is a simple example of a reference model implemented in function call mode:

For instance, this is a simple reference model of an adder:


```python
class AdderRefModel():
    def add(self, a, b):
        return a + b
```

In this reference model, there is no need for any internal state. All functionalities are handled through a single external function interface.

Note that reference models written in function call mode can only be executed through external function calls and cannot output internal data passively. As a result, they cannot be matched with the monitoring methods in an Agent. Writing monitoring methods in the Agent is meaningless when using a reference model written in function call mode.

### Independent Execution Flow Mode 
**Independent execution flow mode**  defines the reference model's behavior as an independent execution flow. Instead of being controlled by external function calls, the reference model can actively fetch input data and output data. When external data is sent to the reference model, it does not respond immediately. Instead, it stores the data and waits for its logic to actively retrieve and process the data.
Here is a code snippet that demonstrates this mode using concepts provided by mlvp, though understanding these concepts in detail is not required at the moment.


```python
class AdderRefModel(Model):
    def __init__(self):
        super().__init__()

        self.add_port = DriverPort()
        self.sum_port = MonitorPort()

    async def main():
        while True:
            operands = await self.add_port()
            sum = operands["a"] + operands["b"]
            await self.sum_port(sum)
```
In this example, two types of interfaces are defined in the constructor of the reference model: a **driver interface (DriverPort)** , represented by `add_port`, which receives external input data, and a **monitoring interface (MonitorPort)** , represented by `sum_port`, which outputs data to the external environment.Once these interfaces are defined, the reference model does not trigger a specific function when data is sent to it. Instead, the data is sent to the `add_port` driver interface. At the same time, external code cannot proactively retrieve output data from the reference model. The model will actively output the result data via the `sum_port` monitoring interface.How does the reference model utilize these interfaces? The reference model has a main function, which is its execution entry point. When the reference model is created, the main function is automatically called and runs continuously in the background. In the code above, the main function continuously waits for data from the `add_port`, computes the result, and outputs the result to the `sum_port`.The reference model actively requests data from the `add_port`, and if there is no data, it waits for new data. Once data arrives, it processes the data and proactively outputs the result to the `sum_port`. This execution flow operates independently and is not controlled by external function calls. When the reference model becomes more complex, with multiple driver and monitoring interfaces, the independent execution flow is particularly useful for handling interactions, especially when the interfaces have a specific call order.
## How to Write a Function Call Mode Reference Model 

### Driver Function Matching 

Suppose the following interface is defined in the Env:


```perl
StackEnv
  - port_agent
    - @driver_method push
    - @driver_method pop
```

If you want to write a reference model that corresponds to this interface, you need to define the behavior of the reference model for each driver function. For each driver function, write a corresponding function in the reference model that will be automatically called when the driver function is invoked.
To match a function in the reference model with a specific driver function, you should use the `@driver_hook` decorator to indicate that the function is a match for a driver function. Then, specify the corresponding Agent and driver function name in the decorator. Finally, ensure that the function parameters match those of the driver function, and the two will be linked.

```python
class StackRefModel(Model):
    @driver_hook(agent_name="port_agent", driver_name="push")
    def push(self, data):
        pass

    @driver_hook(agent_name="port_agent", driver_name="pop")
    def pop(self):
        pass
```

At this point, the driver function is linked with the reference model function. When a driver function in the Env is called, the corresponding reference model function will be automatically invoked, and their return values will be compared.

mlvp also provides several matching methods to improve flexibility:
**Specify the Driver Function Path** 
You can specify the driver function path using a ".". For example:


```python
class StackRefModel(Model):
    @driver_hook("port_agent.push")
    def push(self, data):
        pass

    @driver_hook("port_agent.pop")
    def pop(self):
        pass
```
**Match Driver Function Name with Function Name** If the reference model function name is the same as the driver function name, you can omit the `driver_name` parameter:

```python
class StackRefModel(Model):
    @driver_hook(agent_name="port_agent")
    def push(self, data):
        pass

    @driver_hook(agent_name="port_agent")
    def pop(self):
        pass
```
**Match Both Agent and Driver Function Names** By using a double underscore `__`, you can match both the Agent and the driver function names:

```python
class StackRefModel(Model):
    @driver_hook()
    def port_agent__push(self, data):
        pass

    @driver_hook()
    def port_agent__pop(self):
        pass
```
### Agent Matching 
Instead of writing a separate `driver_hook` for each driver function in the Agent, you can use the `@agent_hook` decorator to match all the driver functions in an Agent at once.

```python
class StackRefModel(Model):
    @agent_hook("port_agent")
    def port_agent(self, driver_name, args):
        pass
```
In this example, the `port_agent` function will match all the driver functions in the `port_agent` Agent. When any driver function in the Agent is called, the `port_agent` function will be invoked automatically. Besides `self`, the `port_agent` function should take exactly two parameters: the first is the name of the driver function, and the second is the arguments passed to the driver function.When a driver function is called, the `driver_name` parameter will receive the name of the driver function, and the `args` parameter will receive the arguments passed during the call, represented as a dictionary. The `port_agent` function can then decide how to handle the driver function call based on `driver_name` and `args` and return the result. The framework will automatically compare the return value of this function with that of the driver function.Similar to driver functions, the `@agent_hook` decorator allows you to omit the `agent_name` parameter when the function name matches the Agent name.

```python
class StackRefModel(Model):
    @agent_hook()
    def port_agent(self, driver_name, args):
        pass
```
**Using Both agent_hook and driver_hook** Once an `agent_hook` is defined, in theory, there is no need to define any `driver_hook` to match driver functions in the Agent. However, if special handling is needed for a specific driver function, a `driver_hook` can still be defined to match that driver function.When both `agent_hook` and `driver_hook` are present, the framework will first call the `agent_hook` function, followed by the `driver_hook` function. The result of the `driver_hook` function will be used for comparison.Once all the driver functions in the Env have corresponding `driver_hook` or `agent_hook` matches, the reference model can be attached to the Env using the `attach` method.
## How to Write an Independent Execution Flow Reference Model 
An independent execution flow reference model handles input and output through `port` interfaces, where it can actively request or send data. In mlvp, two types of interfaces are provided for this purpose: `DriverPort` and `MonitorPort`.Similarly, a series of `DriverPort` objects can be defined to match the driver functions in the Env, and a series of `MonitorPort` objects can be defined to match the monitor functions.When a driver function in the Env is called, the data from the call is sent to the `DriverPort`. The reference model will actively fetch this data, perform calculations, and output the result to the `MonitorPort`. When a monitor function in the Env is called, the comparator will automatically retrieve the data from the `MonitorPort` and compare it with the return value of the monitor function.
### Driver Method Interface Matching 
To receive all driver function calls from the Env, the reference model can define a corresponding `DriverPort` for each driver function. The `DriverPort` parameters `agent_name` and `driver_name` are used to match the driver functions in the Env.

```python
class StackRefModel(Model):
    def __init__(self):
        super().__init__()

        self.push_port = DriverPort(agent_name="port_agent", driver_name="push")
        self.pop_port = DriverPort(agent_name="port_agent", driver_name="pop")
```
Similar to `driver_hook`, you can also match the driver functions in the Env in the following ways:

```python
# Specify the driver function path using "."
self.push_port = DriverPort("port_agent.push")

# If the variable name in the reference model matches the driver function name, you can omit the driver_name parameter
self.push = DriverPort(agent_name="port_agent")

# Match both the Agent name and driver function name using `__` to separate them
self.port_agent__push = DriverPort()
```

### Agent Interface Matching 
You can also define an `AgentPort` to match all driver functions in an Agent. Unlike `agent_hook`, once an `AgentPort` is defined, no `DriverPort` can be defined for any driver function in that Agent. All driver function calls will be sent to the `AgentPort`.

```python
class StackRefModel(Model):
    def __init__(self):
        super().__init__()

        self.port_agent = AgentPort(agent_name="port_agent")
```
Similarly, when the variable name matches the Agent name, you can omit the `agent_name` parameter:

```python
self.port_agent = AgentPort()
```

## Monitor Method Interface Matching 
To match the monitor functions in the Env, the reference model needs to define a corresponding `MonitorPort` for each monitor function. The definition method is the same as for `DriverPort`.

```python
self.monitor_port = MonitorPort(agent_name="port_agent", monitor_name="monitor")

# Specify the monitor function path using "."
self.monitor_port = MonitorPort("port_agent.monitor")

# If the variable name in the reference model matches the monitor function name, you can omit the monitor_name parameter
self.monitor = MonitorPort(agent_name="port_agent")

# Match both the Agent name and monitor function name using `__` to separate them
self.port_agent__monitor = MonitorPort()
```
The data sent to the `MonitorPort` will automatically be compared with the return value of the corresponding monitor function in the Env.Once all `DriverPort`, `AgentPort`, and `MonitorPort` definitions in the reference model successfully match the interfaces in the Env, the reference model can be attached to the Env using the `attach` method.