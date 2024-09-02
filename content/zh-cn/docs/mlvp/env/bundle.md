---
title: 如何使用 Bundle
weight: 2
---

`Bundle` 在 mlvp 验证环境中，用于构建 `Agent` 与 DUT 之间交互的中间层，以保证 `Agent` 与 DUT 之间的解耦。同时 `Bundle` 也起到了对 DUT 接口层次结构划分的作用，使得对 DUT 接口的访问变得更加清晰、方便。

## 一个简单的 Bundle 的定义

为了定义一个 `Bundle`，需要自定义一个新类，并继承 mlvp 中的 `Bundle` 类。下面是一个简单的 `Bundle` 的定义示例：

```python
from mlvp import Bundle, Signals

class AdderBundle(Bundle):
    a, b, sum, cin, cout = Signals(5)
```

该 Bundle 定义了一个简单的加法器接口，在 `AdderBundle` 类中，我们定义了五个信号 `a`, `b`, `sum`, `cin`, `cout`，这五个信号分别代表了加法器的输入端口 `a`, `b`，输出端口 `sum`，以及进位输入端口 `cin` 和进位输出端口 `cout`。

定义完成后，我们可以通过 `AdderBundle` 类的实例来访问这些信号，例如：

```python
adder_bundle = AdderBundle()

adder_bundle.a.value = 1
adder_bundle.b.value = 2
adder_bundle.cin.value = 0
print(adder_bundle.sum.value)
print(adder_bundle.cout.value)
```

## 将 DUT 绑定到 Bundle

在上述代码中，我们虽然创建了一个 bundle 实例，并对他进行了驱动，但是我们并没有将这个 bundle 与任何 DUT 绑定，也就意味着对这个 bundle 的操作，无法真正影响到 DUT。

使用 `bind` 方法，可以将一个 DUT 绑定到 bundle 上。例如我们有一个简单的加法器 DUT，其接口名称与 Bundle 中定义的名称相同。

```
adder = DUTAdder()

adder_bundle = AdderBundle()
adder_bundle.bind(adder)
```

`bind` 函数会自动检索 DUT 中所有的接口，并将名称相同的接口进行绑定。绑定完成后，对 bundle 的操作，就会直接影响到 DUT。

但是，如果 DUT 的接口名称与 Bundle 中定义的名称不同，直接使用 `bind` 则无法正确绑定。在 Bundle 中，我们提供多种绑定方法，以适应不同的绑定需求。

### 通过字典进行绑定

在 `bind` 函数中，我们可以通过传入一个字典，来指定 DUT 中的接口名称与 Bundle 中的接口名称之间的映射关系。

假设 Bundle 中的接口名称与 DUT 中的接口名称拥有如下对应关系：

```
a    -> a_in
b    -> b_in
sum  -> sum_out
cin  -> cin_in
cout -> cout_out
```

在实例化 `bundle` 时，我们可以通过 `from_dict` 方法创建，并传入一个字典，告知 `Bundle` 以字典的方式进行绑定。

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

此时，`adder_bundle` 可正确绑定至 `adder`。

### 通过前缀进行绑定

假设 DUT 中的接口名称与 Bundle 中的接口名称拥有如下对应关系：

```
a    -> io_a
b    -> io_b
sum  -> io_sum
cin  -> io_cin
cout -> io_cout
```

可以发现，实际 DUT 的接口名称相比于 Bundle 中的接口名称，都多了一个 `io_` 的前缀。在这种情况下，我们可以通过 `from_prefix` 方法创建 `Bundle`，并传入前缀名称，告知 `Bundle` 以前缀的方式进行绑定。

```python
adder = DUTAdder()
adder_bundle = AdderBundle.from_prefix('io_')
adder_bundle.bind(adder)
```

### 通过正则表达式进行绑定

在某些情况下，DUT 中的接口名称与 Bundle 中的接口名称之间的对应关系并不是简单的前缀或者字典关系，而是更为复杂的规则。例如，DUT 中的接口名称与 Bundle 中的接口名称之间的对应关系为：

```
a    -> io_a_in
b    -> io_b_in
sum  -> io_sum_out
cin  -> io_cin_in
cout -> io_cout_out
```

在这种情况下，我们可以通过传入正则表达式，来告知 `Bundle` 以正则表达式的方式进行绑定。

```python
adder = DUTAdder()
adder_bundle = AdderBundle.from_regex(r'io_(.*)_.*')
adder_bundle.bind(adder)
```

使用正则表达式时，Bundle 会尝试将 DUT 中的接口名称与正则表达式进行匹配，匹配成功的接口，将会读取正则表达式中的所有捕获组，将其连接为一个字符串。再使用这个字符串与 Bundle 中的接口名称进行匹配。

例如对于上面代码中的正则表达式，`io_a_in` 会与正则表达式成功匹配，唯一的捕获组捕获到的内容为 `a`。`a` 这个名称与 Bundle 中的接口名称 `a` 匹配，因此 `io_a_in` 会被正确绑定至 `a`。



