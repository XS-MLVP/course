---
title: Quick Start
weight: 1
---
## Installation 

### toffee 

[Toffee](https://github.com/XS-MLVP/toffee) is a Python-based hardware verification framework designed to help users build hardware verification environments more conveniently and systematically using Python. It leverages the multi-language conversion tool [picker](https://github.com/XS-MLVP/picker), which converts Verilog code of hardware designs into Python Packages, enabling users to drive and verify hardware designs in Python.

Toffee requires the following dependencies:

- Python 3.6.8+

- Picker 0.9.0+

Once these dependencies are installed, you can install Toffee via pip:

```bash
pip install pytoffee
```

Or install the latest version of Toffee with the following command:

```bash
pip install pytoffee@git+https://github.com/XS-MLVP/toffee@master
```

For a local installation:

```bash
git clone https://github.com/XS-MLVP/toffee.git
cd toffee
pip install .
```

### toffee-test

[toffee-test](https://github.com/XS-MLVP/toffee-test) is a pytest plugin that provides testing support for the toffee framework. It includes identifying test functions as toffee test case objects, making them recognizable and executable by the toffee framework, offering resource management for test cases and providing test report generationto assist users in writing test cases for toffee

To install toffee-test via pip:

```bash
pip install toffee-test
```

Or install the development version:

```bash
pip install toffee-test@git+https://github.com/XS-MLVP/toffee-test@master
```

Or install from source:

```bash
git clone https://github.com/XS-MLVP/toffee-test.git
cd toffee-test
pip install .
```

## Setting Up a Simple Verification Environment 
We will demonstrate how to use mlvp with a simple adder example located in the `example/adder` directory.
The adder design is as follows:


```verilog
module Adder #(
    parameter WIDTH = 64
) (
    input  [WIDTH-1:0] io_a,
    input  [WIDTH-1:0] io_b,
    input              io_cin,
    output [WIDTH-1:0] io_sum,
    output             io_cout
);

assign {io_cout, io_sum} = io_a + io_b + io_cin;

endmodule
```
First, use picker to convert it into a Python package, and then use mlvp to set up the verification environment. After installing the dependencies, run the following command in the `example/adder` directory to complete the conversion:

```bash
make dut
```

To verify the adder's functionality, we will use mlvp to set up a verification environment.
First, we create a driver method for the adder interface using `Bundle` to describe the interface and `Agent` to define the driving methods, as shown below:

```python
class AdderBundle(Bundle):
    a, b, cin, sum, cout = Signals(5)


class AdderAgent(Agent):
    @driver_method()
    async def exec_add(self, a, b, cin):
        self.bundle.a.value = a
        self.bundle.b.value = b
        self.bundle.cin.value = cin
        await self.bundle.step()
        return self.bundle.sum.value, self.bundle.cout.value
```
We use the `driver_method` decorator to mark the `exec_add` method, which drives the adder. Each time the method is called, it assigns the input signals `a`, `b`, and `cin` to the adder's input ports, then reads the output signals `sum` and `cout` after the next clock cycle and returns them.The `Bundle` describes the interface the `Agent` needs to drive. It provides connection methods to the DUT's input and output ports, allowing the `Agent` to drive any DUT with the same interface.Next, we create a reference model to verify the correctness of the adder's output. In mlvp, we use the `Model` class for this, as shown below:

```python
class AdderModel(Model):
    @driver_hook(agent_name="add_agent")
    def exec_add(self, a, b, cin):
        result = a + b + cin
        sum = result & ((1 << 64) - 1)
        cout = result >> 64
        return sum, cout
```
In the reference model, we define the `exec_add` method, which shares the same input parameters as the `exec_add` method in the `Agent`. The method calculates the expected output for the adder. We use the `driver_hook` decorator to associate this method with the `Agent`'s `exec_add` method.
Next, we create a top-level test environment to link the driving methods and the reference model, as shown below:


```python
class AdderEnv(Env):
    def __init__(self, adder_bundle):
        super().__init__()
        self.add_agent = AdderAgent(adder_bundle)

        self.attach(AdderModel())
```

At this point, the verification environment is set up. toffee will automatically drive the reference model, collect results, and compare them with the adder's output.

After that, we can now write several test cases to verify the adder's functionality by toffee-test, as shown below:


```python
@pytest.mark.mlvp_async
async def test_random(mlvp_request):
    env = mlvp_request()

    for _ in range(1000):
        a = random.randint(0, 2**64-1)
        b = random.randint(0, 2**64-1)
        cin = random.randint(0, 1)
        await env.add_agent.exec_add(a, b, cin)

@pytest.mark.mlvp_async
async def test_boundary(mlvp_request):
    env = mlvp_request()

    for cin in [0, 1]:
        for a in [0, 2**64-1]:
            for b in [0, 2**64-1]:
                await env.add_agent.exec_add(a, b, cin)
```

You can run the example in the `example/adder` directory with the following command:

```bash
make run
```
After running, the report will be automatically generated in the `reports` directory.