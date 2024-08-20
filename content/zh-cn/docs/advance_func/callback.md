---
title: 回调函数
description: 利用回调处理电路事件
categories: [示例项目, 教程]
tags: [examples, docs]
weight: 1
draft: true
---
## 回调
### 概述
> 硬件描述语言不同于C++/Python等高级软件编程语言，具有独特的“时钟”特性，在使用picker工具进行验证时，我们可能会遇到想在时钟的上升沿触发某种操作的情况，要想实现这个过程，就要会使用**回调函数**

- 回调函数就是一个**被作为参数**传递的函数。
- 在C语言中，回调函数只能使用**函数指针**实现。
- 在C++、Python、ECMAScript等更现代的编程语言中还可以使用**仿函数或匿名函数**。

回调函数是一个函数或过程，不过它是一个由调用方自己实现，供被调用方使用的特殊函数，一般使用方法如下
- **在a()方法中调用了b()方法**
- **在b方法执行完毕主动调用提供的callback()方法**

这个下面的例子中，实现了一个简单的callback 示例，我们定一个了一个打印结果的方法 print_result，一个两数相加的方法add (), 当完成add 后，调用 print_result（）方法将结果打印出来

```bash hl: title:
def add(x, y):
    return x + y

def sub(x, y):
    return x - y

def mul(x, y):
    return x * y

def div(x, y):
    return x / y

def calc(x, y, func):
    return func(x, y)

# 将函数作为参数传入，再调用函数
print(calc(1, 2, add))
>>> 3
```

### 回调函数的优点
优点
1. 回调函数的作用是将**代码逻辑分离出来**使得代码更加模块化和可维护。。
2. 提高代码的**复用性和灵活性**：回调函数可以将一个函数作为参数传递给另一个函数，从而实现模块化编程，提高代码的复用性和灵活性。
3. 解耦合：回调函数可以将不同模块之间的**关系解耦**，使得代码更易于维护和扩展。
4. 可以异步执行：回调函数可以在异步操作完成后被执行，这样避免了阻塞线程，提高应用程序的效率。

例如在下面这个例子中，我们定义了两个回调函数addOne和addTwo,一个是生成x+1，另一个是生成x+2，还有一个生成倒数的中间函数
- 我们可以通过一个中间函数，来分别调用addOne和addTwo来生成形如1/(x+1)和1/(x+2)形式的数
- 也可以使用匿名函数的形式生成1/(x+3)形式的数
```bash hl: title:

def addOne(x):
    return x + 1


def addTwo(x):
    return x + 2

from even import *

# 中间函数
# 接受一个回调函数作为参数,返回它的倒数
def getNumber(k, getEvenNumber):
    return 1 / getEvenNumber(k)

if __name__ == "__main__":
    x = 1
    # 当需要生成一个1/(x+1)形式的数时
    print(getNumber(x, addOne))
    # 当需要一个1/(x+2)形式的数时
    print(getNumber(x, addTwo))
    # 当需要一个1/(x+3)形式数
    print(getNumber(x, lambda k: k +3))

```
### 回调函数的使用场景包括

1. **事件处理**：回调函数可以用于处理各种事件，例如鼠标点击、键盘输入、网络请求等。
2. **异步操作**：回调函数可以用于异步操作，例如读取文件、发送邮件、下载文件等。
3. **数据处理**：回调函数可以用于处理数据，例如对数组进行排序、过滤、映射等。



### 使用回调函数在时钟上升沿触发操作

下面的[测试代码](#test_random_generator_with_callback)里，我们将在随机数生成器的测试中使用回调函数。

在整个测试过程中，我们会在114514个时钟周期内验证随机数生成器的结果，并统计生成的随机数中大于中位数和小于等于中位数的数量。其中，结果的验证和数据的统计都在时钟上升沿进行。

`TestRandomGenerator`是对随机数生成器进行测试的类，在它的属性和方法中：

+ `self.dut`是用于测试的实例化`DUTRandomGenerator`对象。
+ `self.ref`是用于验证结果的实例化`LFSR_16`对象。
+ `callback1(self, clk)`会对随机数生成器进行验证，在时钟上升沿触发。
+ `callback2(self, clk)`会统计生成随机数的分布，也在时钟上升沿触发。
+ `test_rg(self, callback3)`方法会执行整个测试流程，最后执行`callback3`函数。

Picker生成的DUT类会包含一个驱动电路的时钟源`self.xclock`，`DUTRandomGenerator`也同样如此。

测试前需要把待测模块的`clk`引脚接入时钟源，我们可以调用`dut`中已经封装好的方法：

```python
self.dut.init_clock("clk") # 等价于 self.xclock.Add(self.port["clk"])
```

之后再对生成器进行复位，进行初始化赋值：

```python
self.dut.reset.value = 1
self.dut.Step(1)  # 时钟等待一个周期，下个周期dut的输出会置为0
self.dut.reset.value = 0  # 设置完成后需要记得复位原信号！
```

完成初始化后，添加在时钟上升沿触发的回调函数，用于验证与统计：

```python
self.dut.StepRis(self.callback1)  # 添加在时钟上升沿触发的回调函数
self.dut.StepRis(self.callback2)  # 当然可也添加多个
```

然后等待时钟经过114514个周期，期间每个时钟的上升沿会对结果进行验证并统计生成随机数的分布：

```python
self.dut.Step(114514)
```

最后进行收尾工作，以回调函数的形式调用`median_distribution_stats`输出随机数的分布情况：

```python
self.dut.finalize()
callback3(self.greater, self.less_equal, self.MEDIAN)
```

至此，测试完成。

#### 随机数生成器测试代码{#test_random_generator_with_callback}

```python
from UT_RandomGenerator import *
import random


def median_distribution_stats(gt, le, mid) -> None:
    # 输出产生结果中大于中位数的个数和小于等于中位数的个数。
    print(f"There are {gt} numbers > {mid} and {le} numbers <= {mid}")

# 16位线性移位寄存器模拟类
class LFSR_16:
    def __init__(self, seed):
        self.state = seed & ((1 << 16) - 1)

    def step(self):
        new_bit = (self.state >> 15) ^ (self.state >> 14) & 1
        self.state = ((self.state << 1) | new_bit) & ((1 << 16) - 1)


class TestRandomGenerator:
    def __init__(self) -> None:
        self.MEDIAN = 2**15
        self.SEED = random.randint(0, 2**16 - 1)
        self.greater = 0
        self.less_equal = 0
        self.ref = LFSR_16(self.SEED)
        self.dut = DUTRandomGenerator()

    def test_rg(self, callback3) -> None:
        # clk引脚接入时钟源
        self.dut.init_clock("clk")
        self.dut.seed.value = self.SEED
        # 复位操作
        self.dut.reset.value = 1
        self.dut.Step(1)  # 时钟等待一个周期，下个周期dut的输出会置为0
        self.dut.reset.value = 0  # 设置完成后需要记得复位原信号！
        # 设置回调函数
        self.dut.StepRis(self.callback1)  # 添加在时钟上升沿触发的回调函数
        self.dut.StepRis(self.callback2)  # 当然可也添加多个
        # 测试，启动！
        self.dut.Step(114514) # 等待时钟经过114514个周期
        # 结束
        self.dut.finalize()
        callback3(self.greater, self.less_equal, self.MEDIAN)
        pass

    def callback1(self, clk):
        # 比对结果是否符合预期
        assert self.dut.random_number.value == self.ref.state, "Mismatch"
        print(
            f"Cycle {clk}, DUT: {self.dut.random_number.value:x},"
            + f" REF: {self.ref.state:x}"
        )
        self.ref.step()

    def callback2(self, clk):
        # 统计产生的随机数中，大于中位数和小于等于中位数的分布
        if self.dut.random_number.value > self.MEDIAN:
            self.greater += 1
        else:
            self.less_equal += 1


if __name__ == "__main__":
    TestRandomGenerator().test_rg(median_distribution_stats)
    pass
```


### 在验证加法器时添加回调函数

在这里定义一个32位的加法器`RisAdder`，它只在时钟上升沿更新输出。RTL代码为：

```verilog
module RisAdder #(
    parameter WIDTH = 32
) (
	input              clk,
	input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
reg Cout;
reg [WIDTH-1:0] Sum;

always @(posedge clk) begin
	{Cout, Sum} <= a + b + cin;
end

assign {cout, sum} = {Cout, Sum};

endmodule
```

下面的[测试代码](#test_ris_adder_with_callback)里，我们将在加法器的测试中使用回调函数。

在测试开始前，先创建`DUTRisAdder`对象的实例`dut`和`SimpleRisAdder`对象的实例`ref`。其中，`ref`用于模拟加法器预期的行为，用作参考加法器。

Picker生成的DUT类会包含一个驱动电路的时钟源`self.xclock`，`DUTRisAdder`也同样如此。

在测试开始前，我们会把待测模块的`clk`引脚接入时钟源：

```python3
dut.init_clock("clk") # 等价于 self.xclock.Add(self.port[name])
```

之给加法器的输入置为0，让它下个周期的输出为0：

```python
dut.a.value = 0
dut.b.value = 0
dut.cin.value = 0
dut.Step(1) # 等待时钟进入下个周期
```

随后，添加在时钟上升沿触发的回调函数`test_adder(clk: int, dut: DUTRisAdder, ref: SimpleRisAdder) -> None`，并向`test_adder`传入`dut`和`ref`对象：

```python
# 测试函数，验证加法器的输出是否正确
def test_adder(clk: int, dut: DUTRisAdder, ref: SimpleRisAdder) -> None:
    # 获取加法器的输入和输出
    a = dut.a.value
    b = dut.b.value
    cin = dut.cin.value
    cout = dut.cout.value
    sum = dut.sum.value

    # 检查加法器的输出是否与预期一致
    isEqual = (cout, sum) == (ref.cout, ref.sum)

    # 输出测试结果
    print(f"Cycle: {clk}, Input(a, b, cin) = ({a:x}, {b:x}, {cin:x})")
    print(
        FONT_GREEN + "Pass."  # 输出绿色的“Pass.”，如果测试通过
        if isEqual
        else FONT_RED + f"MisMatch! Expect cout: {ref.cout:x}, sum: {ref.sum:x}." +
        FONT_COLOR_RESET + f"Get cout: {cout:x}, sum: {sum:x}."
    )
    assert isEqual  # 如果测试失败，触发断言异常


if __name__ == "__main__":
    ...
    dut.StepRis(test_adder, (dut, ref))  # 添加在时钟上升沿触发的回调函数, 给回调函数传入dut和ref
   	...
```

`test_adder`函数将会在时钟上升沿比较`dut`和`ref`的输出，验证RTL代码的实现是否符合我们的预期。

最后，执行114514个周期的测试，每个测试数据的信号都会持续一个周期：

```python
# 测试114514个周期
for _ in range(114514):
	a = random.randint(0, (1<<WIDTH) - 1)
	b = random.randint(0, (1<<WIDTH) - 1)
	cin = random.randint(0, 1)
	dut.a.value = a
	dut.b.value = b
	dut.cin.value = cin
	ref.step(a, b, cin) # 更新参考加法器的状态
	dut.Step(1) # 等待时钟进入下个周期

dut.finalize()
```

#### 上升沿更新的加法器的代码{#test_ris_adder_with_callback}

```python
from UT_RisAdder import *
import random

# 控制字体颜色
FONT_GREEN = "\033[0;32m"
FONT_RED = "\033[0;31m"
FONT_COLOR_RESET = "\033[0m"

class SimpleRisAdder:
    """
    SimpleRisAdder 类是一个作为参考的加法器类，
    它模拟了我们预期的RisAdder的行为
    """
    def __init__(self, width) -> None:
        self.WIDTH = width  # 加法器的位宽
        # 端口定义
        self.a = 0  # 输入端口a
        self.b = 0  # 输入端口b
        self.cin = 0  # 输入端口cin
        self.cout = 0  # 输出端口cout
        self.sum = 0   # 输出端口sum

    def step(self, a, b, cin):
        """
        模拟上升沿更新输出: 先用上个周期的输入更新输出，之后再更新输入
        """
        sum = self.a + self.b + self.cin
        self.cout = sum >> self.WIDTH  # 计算进位
        self.sum = sum & ((1 << self.WIDTH) - 1)  # 计算和

        self.a = a  # 更新输入a
        self.b = b  # 更新输入b
        self.cin = cin  # 更新输入cin


# 测试函数，验证加法器的输出是否正确
def test_adder(clk: int, dut: DUTRisAdder, ref: SimpleRisAdder) -> None:
    # 获取加法器的输入和输出
    a = dut.a.value
    b = dut.b.value
    cin = dut.cin.value
    cout = dut.cout.value
    sum = dut.sum.value

    # 验证输出是否符合预期
    isEqual = (cout, sum) == (ref.cout, ref.sum)

    # 输出测试结果
    print(f"Cycle: {clk}, Input(a, b, cin) = ({a:x}, {b:x}, {cin:x})")
    print(
        FONT_GREEN + "Pass."
        if isEqual
        else FONT_RED + f"MisMatch! Expect cout: {ref.cout:x}, sum: {ref.sum:x}.",
        FONT_COLOR_RESET + f"Get cout: {cout:x}, sum: {sum:x}.",
    )
    assert isEqual # 如果测试失败，触发断言异常


if __name__ == "__main__":
    WIDTH = 32  # 设置加法器的位宽
    ref = SimpleRisAdder(WIDTH)  # 创建一个参考加法器
    dut = DUTRisAdder()  # 创建被测试的加法器
    # 绑定时钟信号
    dut.init_clock("clk") # 等价于 self.xclock.Add(self.port[name])
    # dut输入信号置0
    dut.a.value = 0
    dut.b.value = 0
    dut.cin.value = 0
    dut.Step(1) # 等待时钟进入下个周期
    dut.StepRis(test_adder, (dut, ref)) # 添加在时钟上升沿触发的回调函数, 给回调函数传入dut和ref
    # 测试114514个周期
    for _ in range(114514):
        # 随机生成输入
        a = random.randint(0, (1<<WIDTH) - 1)
        b = random.randint(0, (1<<WIDTH) - 1)
        cin = random.randint(0, 1)
        ref.step(a, b, cin) # 更新参考加法器的状态
        dut.a.value = a  # 设置被测试加法器的输入a
        dut.b.value = b  # 设置被测试加法器的输入b
        dut.cin.value = cin  # 设置被测试加法器的输入cin
        dut.Step(1) # 等待时钟进入下个周期

    dut.finalize()
    pass
```

## Eventloop
### 概述
>**Event Loop：**事件循环机制是一种计算机编程模型，其目的是使程序能够在一种非阻塞方式下等待事件(如`输入、计时器、定时器、网络`等)的发生，并在发生事件时被通知及时处理事件，用于等待和分配消息和事件，单线程运行时不会阻塞的一种机制，也就是实现异步的原理。作为一种单线程语言,事件循环机制的核心是**事件循环**，即**程序会轮询事件队列中是否有待处理事件**，如果有，就执行相应的**回调函数**来处理该事件。然后继续等待下一个事件。事件可以是来自外部资源（如网络套接字、文件、定时器等）的输入、用户输入、系统通知等。由此，程序就可以实现**异步、非阻塞**的编程方式，提高程序的响应速度和运行效率.

### 基本原理
事件循环的工作流程通常如下：

1. 启动程序，执行同步代码直到遇到异步代码，
2. 将异步代码的回调函数放入事件队列中，以便在事件发生时执行。
3. 当所有同步代码执行完毕，开始事件循环，不断检查是否有事件发生。
4. 如果有事件队列不为空，则执行与之关联的回调函数。
5. 回到步骤 4，继续循环处理事件。
伪代码的形式如下
```
while(1) {
  events = getEvents();
  for (e in events)
    processEvent(e);
}
```

### Python中的Evenloop
python中的Asyncio模块提供了以下方法来管理事件循环

1.  loop = get_event_loop() : 得到当前的事件循环。
2.  asyncio.set_event_loop() : 为当前上下文设置事件循环。
3.  asyncio.new_event_loop() : 根据此策略创建一个新的事件循环并返回。
4.  loop.call_at():在指定时间的运行。
5.  loop.call_later(delay, callback, arg) : 延迟delay 秒再执行 callback 方法。
6.  loop.call_soon(callback, argument) : 尽可能快调用 callback方法, call_soon() 函数结束，主线程回到事件循环之后就会马上调用 callback 。
7.  loop.time() : 返回当前事件循环的内部时间。
8.  loop.run_forever() : 在调用 stop() 之前将一直运行。

在下面的例子中，我们定义了一个callback方法用于打印参数和loop内时间，以观察函数的定义顺序和执行顺序
- 在main方法中，首先我们先获取当前的事件循环loop，和当前的时间
- 依次调用callback方法，设置不同的开始执行时间

```python
import asyncio

def callback(a, loop):
    print("我的参数为 {0}，执行的时间为{1}".format(a,loop.time()))

if __name__ == "__main__":
    try:
        loop = asyncio.get_event_loop()
        now = loop.time()
        loop.call_later(5, callback, 5, loop)
        loop.call_at(now+2, callback, 2, loop)
        loop.call_at(now+1, callback, 1, loop)
        loop.call_at(now+3, callback, 3, loop)
        loop.call_soon(callback, 4, loop)
        loop.run_forever()  #要用这个run_forever运行
    except KeyboardInterrupt:
        print("Goodbye!")

```

运行结果为：
```
我的参数为 4，执行的时间为266419.843
我的参数为 1，执行的时间为266420.843
我的参数为 2，执行的时间为266421.859
我的参数为 3，执行的时间为266422.859
我的参数为 5，执行的时间为266424.843
```

### 回调函数和Eventloop的缺点
回调函数也存在如下的一些缺点，因此在下一小节中引入了异步的概念，
缺点：
1. 回调函数嵌套过多会导致代码难以维护：如果回调函数嵌套层数过多，代码会变得非常复杂，难以维护。
2. 回调函数容易造成竞态条件：如果回调函数中有共享资源访问，容易出现竞态条件，导致程序出错。
3. 代码可读性差：回调函数的使用可能会破坏代码的结构和可读性，尤其是在处理大量数据时
