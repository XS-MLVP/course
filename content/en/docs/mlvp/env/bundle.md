---
title: How to Use Bundle
weight: 2
---

`Bundle` serves as an intermediary layer in the mlvp verification environment, facilitating interaction between the `Agent` and the DUT while ensuring their decoupling. Additionally, `Bundle` helps define the hierarchy of DUT interface layers, making access to the DUT interface clearer and more convenient.
## A Simple Definition of a Bundle 
To define a `Bundle`, you need to create a new class that inherits from the `Bundle` class in mlvp. Here’s a simple example of defining a `Bundle`:

```python
from mlvp import Bundle, Signals

class AdderBundle(Bundle):
    a, b, sum, cin, cout = Signals(5)
```
This Bundle defines a simple adder interface. In the `AdderBundle` class, we define five signals: `a`, `b`, `sum`, `cin`, and `cout`, which represent the input ports `a` and `b`, the output port `sum`, and the carry input and output ports `cin` and `cout`, respectively.After the definition, we can access these signals through an instance of the `AdderBundle` class, for example:

```python
adder_bundle = AdderBundle()

adder_bundle.a.value = 1
adder_bundle.b.value = 2
adder_bundle.cin.value = 0
print(adder_bundle.sum.value)
print(adder_bundle.cout.value)
```

## Binding the DUT to the Bundle 

In the code above, we created an instance of a bundle and drove it, but we did not bind this bundle to any DUT, which means operations on this bundle cannot actually affect the DUT.
Using the `bind` method, we can bind a DUT to a bundle. For example, if we have a simple adder DUT whose interface names match those defined in the Bundle:

```python
adder = DUTAdder()

adder_bundle = AdderBundle()
adder_bundle.bind(adder)
```
The `bind` function will automatically retrieve all interfaces from the DUT and bind those with the same names. Once bound, operations on the bundle will directly affect the DUT.However, if the interface names of the DUT differ from those defined in the Bundle, using `bind` directly will not bind them correctly. In the Bundle, we provide various binding methods to accommodate different binding needs.
### Binding via a Dictionary 
In the `bind` function, you can specify a mapping between the DUT's interface names and the Bundle's interface names by passing in a dictionary.
Suppose the interface names in the Bundle correspond to those in the DUT as follows:


```rust
a    -> a_in
b    -> b_in
sum  -> sum_out
cin  -> cin_in
cout -> cout_out
```
When instantiating the `bundle`, we can create it using the `from_dict` method and provide a dictionary to inform the `Bundle` to bind in this way.

```python
adder = DUTAdder()
adder_bundle = AdderBundle.from_dict({
    'a': 'a_in',
    'b': 'b_in',
    'sum': 'sum_out',
    'cin': 'cin_in',
    'cout': 'cout_out'
})
adder_bundle.bind(adder)
```
Now, `adder_bundle` is correctly bound to `adder`.
### Binding via a Prefix 

If the DUT's interface names correspond to those in the Bundle as follows:


```rust
a    -> io_a
b    -> io_b
sum  -> io_sum
cin  -> io_cin
cout -> io_cout
```
You can see that the DUT's interface names have an `io_` prefix compared to those in the Bundle. In this case, you can create the `Bundle` using the `from_prefix` method, providing the prefix name to instruct the `Bundle` to bind using the prefix.

```python
adder = DUTAdder()
adder_bundle = AdderBundle.from_prefix('io_')
adder_bundle.bind(adder)
```

### Binding via Regular Expressions 

In some cases, the correspondence between the DUT's interface names and the Bundle's interface names may not be a simple prefix or dictionary relationship but instead follow more complex rules. For example, the mapping may be:


```rust
a    -> io_a_in
b    -> io_b_in
sum  -> io_sum_out
cin  -> io_cin_in
cout -> io_cout_out
```
In such cases, you can pass a regular expression to inform the `Bundle` to bind using that regular expression.

```python
adder = DUTAdder()
adder_bundle = AdderBundle.from_regex(r'io_(.*)_.*')
adder_bundle.bind(adder)
```

When using a regular expression, the Bundle attempts to match the DUT's interface names with the regular expression. For successful matches, the Bundle reads all capture groups from the regular expression, concatenating them into a string. This string is then used to match against the Bundle's interface names.
For example, in the code above, `io_a_in` matches the regular expression successfully, capturing `a` as the unique capture group. The name `a` matches the Bundle's interface name `a`, so `io_a_in` is correctly bound to `a`.
## Creating Sub-Bundles 

Often, we may need a Bundle to contain one or more other Bundles. In this case, we can include already defined Bundles as sub-Bundles of the current Bundle.


```python
from mlvp import Bundle, Signal, Signals

class AdderBundle(Bundle):
    a, b, sum, cin, cout = Signals(5)

class MultiplierBundle(Bundle):
    a, b, product = Signals(3)

class ArithmeticBundle(Bundle):
    selector = Signal()

    adder = AdderBundle.from_prefix('add_')
    multiplier = MultiplierBundle.from_prefix('mul_')
```
In the code above, we define an `ArithmeticBundle` that contains its own signal `selector`. In addition, it includes an `AdderBundle` and a `MultiplierBundle`, which are named `adder` and `multiplier`, respectively.When accessing the sub-Bundles within the `ArithmeticBundle`, you can use the `.` operator:

```python
arithmetic_bundle = ArithmeticBundle()

arithmetic_bundle.selector.value = 1
arithmetic_bundle.adder.a.value = 1
arithmetic_bundle.adder.b.value = 2
arithmetic_bundle.multiplier.a.value = 3
arithmetic_bundle.multiplier.b.value = 4
```

Furthermore, when defining in this manner, binding the top-level Bundle will also bind the sub-Bundles to the DUT. The previously mentioned various binding methods can still be used when defining sub-Bundles.
It is important to note that the method for creating sub-Bundles matches signal names that have been processed by the previous Bundle's creation method. For example, in the code above, if the top-level Bundle's matching method is set to `from_prefix('io_')`, then the signal names matched within the `AdderBundle` will be those stripped of the `io_` prefix.
Similarly, the dictionary matching method will pass the names transformed into the mapped names for matching with the sub-Bundle, while the regular expression matching method will pass the names captured by the regular expression for matching with the sub-Bundle.
## Practical Operations in a Bundle 

### Signal Access and Assignment 
**Accessing Signal Values** In a Bundle, signals can be accessed not only through the `.` operator but also through the `[]` operator.

```python
adder_bundle = AdderBundle()
adder_bundle['a'].value = 1
```
**Accessing Unconnected Signals** 

```python
def bind(self, dut, unconnected_signal_access=True)
```
When binding, you can pass the `unconnected_signal_access` parameter to control whether accessing unconnected signals is allowed. By default, it is `True`, meaning unconnected signals can be accessed. In this case, writing to the signal will not change it, and reading the signal will return `None`. When `unconnected_signal_access` is set to `False`, accessing unconnected signals will raise an exception.**Assigning All Signals Simultaneously** You can use the `set_all` method to change all input signals at once.

```python
adder_bundle.set_all(0)
```
**Changing Signal Assignment Mode** The signal assignment mode is a concept in `picker` that controls how signals are assigned. Please refer to the `picker` documentation for more details.In a Bundle, you can change the assignment mode for the entire Bundle using the `set_write_mode` method.Additionally, there are shortcut methods: `set_write_mode_as_imme`, `set_write_mode_as_rise`, and `set_write_mode_as_fall`, which set the Bundle's assignment mode to immediate, rising edge, and falling edge assignments, respectively.
### Message Support 
**Default Message Type Assignment** `mlvp` supports assigning a default message type to a Bundle's signals using the `assign` method with a dictionary.

```python
adder_bundle.assign({
    'a': 1,
    'b': 2,
    'cin': 0
})
```
The Bundle will automatically assign the values from the dictionary to the corresponding signals. If you want to assign unspecified signals to a default value, use `*` to specify a default value:

```python
adder_bundle.assign({
    '*': 0,
    'a': 1,
})
```
**Default Message Assignment for Sub-Bundles** If you want to assign signals in sub-Bundles using default message types, this can be achieved in two ways. When the `multilevel` parameter in `assign` is set to `True`, the Bundle supports multi-level dictionary assignments.

```python
arithmetic_bundle.assign({
    'selector': 1,
    'adder': {
        '*': 0,
        'cin': 0
    },
    'multiplier': {
        'a': 3,
        'b': 4
    }
}, multilevel=True)
```
When `multilevel` is `False`, the Bundle supports specifying sub-Bundle signals using the `.` operator.

```python
arithmetic_bundle.assign({
    '*': 0,
    'selector': 1,
    'adder.cin': 0,
    'multiplier.a': 3,
    'multiplier.b': 4
}, multilevel=False)
```
**Reading Default Message Types** You can convert the current signal values in a Bundle into a dictionary using the `as_dict` method. It supports two formats: when `multilevel` is `True`, a multi-level dictionary is returned; when `multilevel` is `False`, a flattened dictionary is returned.

```python
> arithmetic_bundle.as_dict(multilevel=True)
{
    'selector': 1,
    'adder': {
        'a': 0,
        'b': 0,
        'sum': 0,
        'cin': 0,
        'cout': 0
    },
    'multiplier': {
        'a': 0,
        'b': 0,
        'product': 0
    }
}
```


```python
> arithmetic_bundle.as_dict(multilevel=False)
{
    'selector': 1,
    'adder.a': 0,
    'adder.b': 0,
    'adder.sum': 0,
    'adder.cin': 0,
    'adder.cout': 0,
    'multiplier.a': 0,
    'multiplier.b': 0,
    'multiplier.product': 0
}
```
**Custom Message Types** 
In custom message structures, rules can be defined to assign signals to a Bundle.
One approach is to implement the `as_dict` function in the custom message structure to convert it into a dictionary, which can then be assigned to the Bundle using the `assign` method.Another approach is to implement the `__bundle_assign__` function in the custom message structure, which accepts a Bundle instance and assigns values to its signals. Once this is implemented, the `assign` method can be used to assign the message to the Bundle, and the Bundle will automatically call the `__bundle_assign__` function for assignment.

```python
class MyMessage:
    def __init__(self):
        self.a = 0
        self.b = 0
        self.cin = 0

    def __bundle_assign__(self, bundle):
        bundle.a.value = self.a
        bundle.b.value = self.b
        bundle.cin.value = self.cin

my_message = MyMessage()
adder_bundle.assign(my_message)
```
When you need to convert the signal values in a Bundle into a custom message structure, implement a `from_bundle` class method in the custom message structure. This method accepts a Bundle instance and returns the custom message structure.

```python
class MyMessage:
    def __init__(self):
        self.a = 0
        self.b = 0
        self.cin = 0

    @classmethod
    def from_bundle(cls, bundle):
        message = cls()
        message.a = bundle.a.value
        message.b = bundle.b.value
        message.cin = bundle.cin.value
        return message

my_message = MyMessage.from_bundle(adder_bundle)
```
### Timing Encapsulation 
In addition to encapsulating DUT pins, the `Bundle` class also provides timing encapsulation based on arrays, which can be applied to simple timing scenarios. The `Bundle` class offers a `process_requests(data_list)` function that accepts an array as input. On the `i-th` clock cycle, `data_list[i]` will assign the corresponding data to the pins. The `data_list` can contain data in the form of a `dict` or a callable object (`callable(cycle, bundle_ins)`). For the `dict` type, special keys include:

```bash
__funcs__: func(cycle, self)  # Callable object, can be an array of functions [f1, f2, ..]
__condition_func__: func(cycle, self, cargs)  # Conditional function, assignment occurs when this returns true, otherwise, the clock advances
__condition_args__: cargs  # Arguments for the conditional function
__return_bundles__: bundle  # Specifies which bundle data should be returned when this dict is processed. Can be list[bundle]
```
If the input `dict` contains `__return_bundles__`, the function will return the corresponding bundle values, such as `{"data": x, "cycle": y}`. For example, consider the Adder bundle where the result is expected after the third addition:

```python
# The Adder is combinational logic but used here as sequential logic
class AdderBundle(Bundle):
    a, b, sum, cin, cout = Signals(5)  # Define the pins

    def __init__(self, dut):
        super().__init__()
        # init clock
        # dut.InitClock("clock")
        self.bind(dut)  # Bind to the DUT

    def add_list(data_list=[(1, 2), (3, 4), (5, 6), (7, 8)]):
        # Create the input dict
        data = []
        for i, (a, b) in enumerate(data_list):
            x = {"a": a, "b": b, "*": 0}  # Build the dict for bundle assignment
            if i >= 2:
                x["__return_bundles__"] = self  # Set the bundle to be returned
        return self.process_requests(data)  # Drive the clock, assign values, return results
```
After calling `add_list()`, the returned result is:

```python
[
  {"data": {"a":5, "b":6, "cin": 0, "sum":11, "cout": 0}, "cycle":3},
  {"data": {"a":7, "b":8, "cin": 0, "sum":15, "cout": 0}, "cycle":4}
]
```

### Asynchronous Support 
In the `Bundle`, a `step` function is provided to conveniently synchronize with the clock signal of the DUT. When the `Bundle` is connected to any signal of the DUT, the `step` function automatically synchronizes with the DUT's clock signal.The `step` function can be used to wait for clock cycles.

```python
async def adder_process(adder_bundle):
    adder_bundle.a.value = 1
    adder_bundle.b.value = 2
    adder_bundle.cin.value = 0
    await adder_bundle.step()
    print(adder_bundle.sum.value)
    print(adder_bundle.cout.value)
```

### Signal Connectivity 
**Signal Connectivity Rules** Once the `Bundle` instance is defined, you can call the `all_signals_rule` method to get the connection rules for all signals, helping the user check if the connection rules are as expected.

```python
adder_bundle.all_signals_rule()
```
**Signal Connectivity Check** The `detect_connectivity` method checks if a specific signal name can connect to any signal in the `Bundle`.

```python
adder_bundle.detect_connectivity('io_a')
```
The `detect_specific_connectivity` method checks if a specific signal name can connect to a particular signal in the `Bundle`.

```python
adder_bundle.detect_specific_connectivity('io_a', 'a')
```
To check connectivity for signals in sub-Bundles, use the `.` operator to specify the sub-Bundle.
### DUT Signal Connectivity Check 
**Unconnected Signal Check** The `detect_unconnected_signals` method checks for any signals in the DUT that are not connected to any `Bundle`.

```python
Bundle.detect_unconnected_signals(adder)
```
**Duplicate Connection Check** The `detect_multiple_connections` method checks for signals in the DUT that are connected to multiple `Bundles`.

```python
Bundle.detect_multiple_connections(adder)
```

### Other Practical Operations 
**Set Bundle Name** You can set the name of a `Bundle` using the `set_name` method.

```python
adder_bundle.set_name('adder')
```

Once the name is set, more intuitive prompt information is provided.
**Get All Signals in the Bundle** The `all_signals` method returns a generator containing all signals, including those in sub-Bundles.

```python
for signal in adder_bundle.all_signals():
    print(signal)
```

## Automatic Bundle Generation Script 
In many cases, the interface of a DUT can be complex, making it tedious to manually write the `Bundle` definitions. However, since `Bundle` serves as an intermediate layer, providing an exact definition of signal names is essential. To address this, `mlvp` provides an automatic generation script that generates `Bundle` definitions from the DUT's interface.The script `bundle_code_gen.py` can be found in the `scripts` folder of the `mlvp` repository. This script can automatically generate `Bundle` definitions by parsing a DUT instance and the specified binding rules.
It provides three functions:


```python
def gen_bundle_code_from_dict(bundle_name: str, dut, dict: dict, max_width: int = 120)
def gen_bundle_code_from_prefix(bundle_name: str, dut, prefix: str = "", max_width: int = 120):
def gen_bundle_code_from_regex(bundle_name: str, dut, regex: str, max_width: int = 120):
```
These functions generate `Bundle` definitions based on a dictionary, prefix, or regular expression, respectively.To use, specify the `Bundle` name, DUT instance, and the corresponding generation rules to generate the `Bundle` definition. You can also use the `max_width` parameter to set the maximum width of the generated code.

```python
from bundle_code_gen import *

gen_bundle_code_from_dict('AdderBundle', dut, {
    'a': 'io_a',
    'b': 'io_b',
    'sum': 'io_sum',
    'cin': 'io_cin',
    'cout': 'io_cout'
})
gen_bundle_code_from_prefix('AdderBundle', dut, 'io_')
gen_bundle_code_from_regex('AdderBundle', dut, r'io_(.*)')
```
The generated code can be copied directly into your project or used with minor modifications. It can also serve as a sub-Bundle definition for use in other `Bundles`.
