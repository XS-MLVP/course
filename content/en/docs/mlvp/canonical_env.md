---
title: Writing a Standardized Verification Environment
weight: 2
---
## Overview 
The main task of writing verification code can be broadly divided into two parts: **building the verification environment**  and **writing test cases** .**Building the verification environment**  aims to encapsulate the Design Under Test (DUT) so that the verification engineer does not have to deal with complex interface signals when driving the DUT, but can instead directly use the high-level interfaces provided by the verification environment. If a reference model needs to be written, it should also be part of the verification environment.**Writing test cases**  involves using the interfaces provided by the verification environment to write individual test cases for functional verification of the DUT.
Building the verification environment can be quite challenging, especially when the DUT is highly complex with numerous interface signals. In such cases, without a unified standard, constructing the verification environment can become chaotic, making it difficult for one person’s verification environment to be maintained by others. Additionally, when new verification tasks overlap with existing ones, it can be difficult to reuse the previous verification environment due to the lack of standardization.

This section will introduce the characteristics that a standardized verification environment should have, which will help in understanding the process of building the verification environment in mlvp.

## Non-Reusable Verification Code 
Take a simple adder as an example, which has two input ports, `io_a` and `io_b`, and one output port, `io_sum`. If we do not consider the possibility of reusing the verification code for other tasks, we might write the following driving code:

```python
def exec_add(dut, a, b):
    dut.io_a.value = a
    dut.io_b.value = b
    dut.Step(1)
    return dut.io_sum.value
```
In the above code, we wrote an `exec_add` function, which essentially encapsulates the addition operation of the adder at a high level. With the `exec_add` function, we no longer need to worry about how to assign values to the interface signals of the adder or how to drive the adder and retrieve its output. We simply need to call the `exec_add` function to drive the adder and complete an addition operation.
However, this driving function has a major drawback—it directly uses the DUT’s interface signals to interact with the DUT, meaning that this driving function can only be used for this specific adder.
Unlike software testing, in hardware verification, we frequently encounter scenarios where the interface structures are identical. Suppose we have another adder with the same functionality, but its interface signals are named `io_a_0`, `io_b_0`, and `io_sum_0`. In this case, the original driving function would fail and could not be reused. To drive this new adder, we would have to rewrite a new driving function.
If writing a driving function for an adder is already this problematic, imagine the difficulty when dealing with a DUT with complex interfaces. After putting in a lot of effort to write the driving code for such a DUT, we might later realize that the code needs to be migrated to a similar structure with some changes in the interface, leading to a significant amount of rework. Issues such as interface name changes, missing or additional signals, or unused references in the driving code would emerge.

The root cause of these issues lies in directly operating the DUT’s interface signals in the verification code. As illustrated in the diagram below, this approach is problematic:


```lua
+-----------+   +-----------+
|           |-->|           |
| Test Code |   |    DUT    |
|           |<--|           |
+-----------+   +-----------+
```

## Decoupling Verification Code from the DUT 
To solve the above problems, we need to decouple the verification code from the DUT, so that the verification code no longer directly manipulates the DUT’s interface signals. Instead, it interacts with the DUT through an intermediate layer. This intermediate layer is a user-defined interface structure, referred to as a `Bundle` in mlvp, and we will use `Bundle` to represent this intermediate layer throughout the document.Using the adder as an example, we can define a `Bundle` structure that includes the signals `a`, `b`, and `sum`, and let the test code interact directly with this Bundle:

```python
def exec_add(bundle, a, b):
    bundle.a.value = a
    bundle.b.value = b
    bundle.Step(1)
    return bundle.sum.value
```
In this case, the `exec_add` function does not directly manipulate the DUT’s interface signals, and it does not even need to know the names of the DUT’s interface signals. It interacts directly with the signals defined in the `Bundle`.How do we connect the signals in the `Bundle` to the DUT’s pins? This can be done by simply specifying how each signal in the `Bundle` is connected to the DUT’s pins. For example:

```rust
bundle.a   <-> dut.io_a
bundle.b   <-> dut.io_b
bundle.sum <-> dut.io_sum
```

If the DUT’s interface signal names change, we only need to modify this connection process:


```rust
bundle.a   <-> dut.io_a_0
bundle.b   <-> dut.io_b_0
bundle.sum <-> dut.io_sum_0
```

In this way, regardless of how the DUT’s interface changes, as long as the structure remains the same, we can use the original driving code to operate the DUT, with only the connection process needing adjustment. The relationship between the verification code and the DUT now looks like this:


```lua
+-----------+  +--------+             +-----------+
|           |->|        |             |           |
| Test Code |  | Bundle |-- connect --|    DUT    |
|           |<-|        |             |           |
+-----------+  +--------+             +-----------+
```
In mlvp, we provide a simple way to define `Bundles` and a variety of connection methods to make defining and connecting the intermediate layer easy. Additionally, `Bundles` offer many practical features to help verification engineers interact with interface signals more effectively.
## Categorizing DUT Interfaces for Driving 
We now know that a `Bundle` must be defined to decouple the test code from the DUT. However, if the DUT’s interface signals are too complex, we might face a new issue—only this particular DUT can be connected to the `Bundle`. This is because we would be defining a `Bundle` structure that includes all the DUT’s pins, meaning only a DUT with an identical interface could be connected to this `Bundle`, which is too restrictive.In such cases, the intermediate layer loses its purpose. However, we often observe that a DUT’s interface structure is logically organized and usually composed of several independent sub-interfaces. For example, the dual-port stack mentioned [here](https://open-verify.cc/mlvp/docs/quick-start/eg-stack-callback/)  has two sub-interfaces with identical structures. Instead of covering the entire dual-port stack interface in a single `Bundle`, we can split it into two `Bundles`, each corresponding to one sub-interface.Moreover, for the dual-port stack, the two sub-interfaces have identical structures, so we can use the same `Bundle` to describe both sub-interfaces without redefining it. Since both share the same `Bundle`, the driving code written for this `Bundle` is fully reusable! This is the essence of reusability in verification environments.In summary, for every DUT, we should divide its interface signals into several independent sub-interfaces, each with its own function, and then define a `Bundle` for each sub-interface. The driving code for each `Bundle` should then be written.
At this point, the relationship between the verification code and the DUT looks like this:


```lua
+-----------+  +--------+             +-----------+
|           |->|        |             |           |
| Test Code |  | Bundle |-- connect --|           |
|           |<-|        |             |           |
+-----------+  +--------+             |           |
                                      |           |
     ...           ...                |    DUT    |
                                      |           |
+-----------+  +--------+             |           |
|           |->|        |             |           |
| Test Code |  | Bundle |-- connect --|           |
|           |<-|        |             |           |
+-----------+  +--------+             +-----------+
```

Now, our approach to building the verification environment becomes clear: we write high-level abstractions for each independent sub-interface.

## Structure of Independent Interface Drivers 
We write high-level abstractions for each `Bundle`, and these pieces of code are independent and highly reusable. If we separate the interaction logic between the high-level operations and place it in the test cases, then a combination of multiple `Test Code + Bundle` units will form the entire driving environment for the DUT.We can assign a name to each `Test Code + Bundle` combination. In mlvp, this structure is called an `Agent`. An `Agent` is independent of the DUT and handles all interactions with a specific interface.
The relationship between the verification code and the DUT now looks like this:


```lua
+---------+    +-----------+
|         |    |           |
|  Agent  |----|           |
|         |    |           |
+---------+    |           |
               |           |
    ...        |    DUT    |
               |           |
+---------+    |           |
|         |    |           |
|  Agent  |----|           |
|         |    |           |
+---------+    +-----------+
```
Thus, the process of building the driving environment is essentially the process of writing one `Agent` after another. However, we have not yet discussed how to write a standardized `Agent`. If everyone writes `Agents` differently, the verification environment will still become difficult to manage.


## Writing a Standardized “Agent” 
To understand how to write a standardized `Agent`, we first need to grasp the main functions an `Agent` is supposed to accomplish. As mentioned earlier, an `Agent` implements all the interactions with a specific class of interfaces and provides high-level abstraction.
Let’s explore the interactions between the verification code and the interface. Assuming that the verification code has the ability to read input ports, we can categorize the interactions based on whether the verification code actively initiates communication or passively receives data, as follows:
 
1. **Verification Code Actively Initiates** 
  - Actively reads the value of input/output ports

  - Actively assigns values to input ports
 
2. **Verification Code Passively Receives** 
  - Passively receives the values of output/input ports
These two types of operations cover all interactions between the verification code and the interface, so an `Agent` must support both.
### Interactions Actively Initiated by the Verification Code 
Let’s first consider the two types of interactions actively initiated by the verification code. To encapsulate these interactions at a high level, the `Agent` must have two capabilities:
1. The driver should be able to convert high-level semantic information into assignments to interface signals.

2. It should convert interface signals into high-level semantic information and return this to the initiator.
There are various ways to implement these interactions. However, since mlvp is a verification framework based on a software testing language, and we want to keep the verification code as simple as possible, mlvp standardizes the use of **functions**  to carry out these interactions.
Because functions are the most basic abstraction unit in programming, their input parameters can directly represent high-level semantic information and be passed to the function body. Within the function body, assignments and reading operations can handle the translation between semantic information and interface signals. Finally, the return value can be used to pass the converted interface signal back to the initiator as high-level semantic information.
In mlvp, such functions that facilitate interactions actively initiated by the verification code are called **driver methods** . In mlvp, we use the `driver_method` decorator to mark these functions.
### Interactions Passively Received by the Verification Code 

Next, let’s look at interactions passively received by the verification code. These interactions occur when the interface sends output signals to the verification code upon meeting specific conditions, without the verification code actively initiating the process.

For example, the verification code might want to passively obtain output signals from the DUT after the DUT completes an operation and convert them into high-level semantic information. Alternatively, the verification code might want to passively retrieve output signals at every cycle and convert them.
Similar to the `driver_method`, mlvp also standardizes the use of **functions**  to carry out this type of interaction. However, these functions have no input parameters and are not actively controlled by the verification code. When specific conditions are met, the function is triggered to read interface signals and convert them into high-level semantic information. This information is then stored for later use by the verification code.These functions in mlvp, which facilitate passively received interactions, are referred to as **monitor methods** . We use the `monitor_method` decorator in mlvp to mark such functions.
### A Standardized “Agent” Structure 
In summary, we use **functions**  as carriers to facilitate all interactions between the verification code and the interface. These functions are categorized into two types: **driver methods**  and **monitor methods** . These methods handle the interactions actively initiated and passively received by the verification code, respectively.Thus, writing an `Agent` essentially involves creating a series of driver methods and monitor methods. Once an `Agent` is created, simply providing the list of its internal driver and monitor methods will describe the entire functionality of the `Agent`.An `Agent` structure can be described using the following diagram:

```sql
+--------------------+
| Agent              |
|                    |
|   @driver_method   |
|   @driver_method   |
|   ...              |
|                    |
|   @monitor_method  |
|   @monitor_method  |
|   ...              |
|                    |
+--------------------+
```

## Verifying the DUT’s Functional Correctness 
At this point, we have completed the encapsulation of high-level operations on the DUT and established interaction between the verification code and the DUT through functions. Now, to verify the functional correctness of the DUT, we would write test cases that use the **driver methods**  to drive the DUT through specific operations. Simultaneously, the **monitor methods**  are automatically triggered to collect relevant information from the DUT.**But how do we verify that the DUT’s functionality is correct?** 
After driving the DUT in the test case, the output information we obtain from the DUT comes in two forms: one is actively retrieved through the driver methods, and the other is collected through the monitor methods. Therefore, verifying the DUT’s functionality essentially involves checking whether this information matches the expected results.
**How do we determine whether this information is as expected?** 
In one case, we already know what the DUT’s output should be or what conditions it should meet. In this situation, after obtaining the information in the test case, we can directly check it against our expectations.
In another case, we do not know the expected output of the DUT. In this scenario, we can create a **Reference Model (RM)**  with the same functionality as the DUT. Whenever we send input to the DUT, we simultaneously send the same input to the reference model.
To verify the two types of output information, we can compare the DUT's output with the reference model’s output, obtained at the same time, to ensure consistency.
These are the two methods of verifying the DUT’s correctness: **direct comparison**  and **reference model comparison** .
## How to Add a Reference Model 

For direct comparison, the comparison logic can be written directly into the test case. However, if we use the reference model method, the test case might involve additional steps: sending information to both the DUT and the model simultaneously, collecting both DUT and model outputs, and writing logic for comparing passive signals from the DUT with the reference model. This can clutter the test case code and mix the reference model interaction logic with the test logic, making maintenance difficult.

We can observe that every call to a driver function represents an operation on the DUT, which also needs to be forwarded to the reference model. The reference model doesn’t need to know how the DUT’s interface is driven; it only needs to process high-level semantic information and update its internal state. Therefore, the reference model only needs to receive the high-level semantic information (i.e., the input parameters of the driver function).

Thus, the reference model only needs to define how to react when driver functions are called. The task of passing call information to the reference model can be handled by the framework. Similarly, comparing return values or monitor signals can also be automatically managed by the framework.

With this, test cases only need to focus on driving the DUT, while synchronization and comparison with the reference model will be automatically managed by the framework.
To achieve reference model synchronization, mlvp defines a set of reference model matching specifications. By following these specifications, you can automatically forward and compare data to the reference model. Additionally, mlvp provides the `Env` concept to package the entire verification environment. Once the reference model is implemented, it can be linked to the `Env` for automatic synchronization.
## Conclusion 

Thus, our verification environment becomes the following structure:


```lua
+--------------------------------+
| Env                            |
|                  +-----------+ |  +-----------+
|   +---------+    |           | |  |           |
|   |  Agent  |----|           | |->| Reference |
|   +---------+    |    DUT    | |  |   Model   |
|   +---------+    |           | |<-|           |
|   |  Agent  |----|           | |  |           |
|   +---------+    |           | |  +-----------+
|       ...        +-----------+ |
+--------------------------------+
```
At this stage, building the verification environment becomes clear and standardized. For reuse, you simply select the appropriate `Agent`, connect it to the DUT, and package everything into an `Env`. To implement a reference model, you just follow the `Env` interface specification and implement the reference model logic.The test cases are separated from the verification environment. Once the environment is set up, the interfaces provided by each `Agent` can be used to write the driving logic for the test cases. The synchronization and comparison with the reference model will be automatically handled by the framework.
This is the idea behind constructing the verification environment in mlvp, which offers many features to help you build a standardized verification environment. It also provides test case management methods to make writing and managing test cases easier.