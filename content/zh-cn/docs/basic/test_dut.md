---
title: DUT验证
description:  介绍验证的一般流程
categories: [示例项目, 学习材料]
tags: [examples, docs]
weight: 5
---

{{% pageinfo %}}
本节介绍基于Picker验证DUT的一般流程
{{% /pageinfo %}}

开放验证平台的目标是功能性验证，其一般有以下步骤：
### 1. 确定验证对象和目标
通常来说，同时交付给验证工程师的还有DUT的设计文档。此时您需要阅读文档或者源代码，了解验证对象的基本功能、主体结构以及预期功能。

### 2. 构建基本验证环境
充分了解设计之后，您需要构建验证的基本环境。例如，除了由Picker生成的DUT外，您可能还需要搭建用于比对的参考模型，也可能需要为后续功能点的评测搭建信号的监听平台。

### 3. 功能点与测试点分解
在正式开始验证之前，您还需要提取功能点，并将其进一步分解成测试点。提取和分解方法可以参考：[CSDN:芯片验证系列——Testpoints分解](https://blog.csdn.net/W1Z1Q/article/details/124547192)

### 4. 构造测试用例
有了测试点之后，您需要构造测试用例来覆盖相应的测试点。一个用例可能覆盖多个测试点。

### 5. 收集测试结果
运行完所有的测试用例之后，您需要汇总所有的测试结果。一般来说包括代码行覆盖率以及功能覆盖率。前者可以通过Picker工具提供的覆盖率功能获得，后者则需要您通过监听DUT的行为判断某功能是否被用例覆盖到。

### 6. 评估测试结果
最后您需要评估得到的结果，如是否存在错误的设计、某功能是否无法被触发、设计文档表述是否与DUT行为一致、设计文档是否表述清晰等。

---
接下来我们以**果壳Cache的MMIO读写为例**，介绍一般验证流程：

**1 确定验证对象和目标**：  
果壳Cache的MMIO读写功能。MMIO是一类特殊的IO映射，其支持通过访问内存地址的方式访问IO设备寄存器。由于IO设备的寄存器状态是随时可能改变的，因此不适合将其缓存在cache中。当收到MMIO请求时，果壳cache不会在普通的cache行中查询命中/缺失情况，而是会直接访问MMIO的内存区域来读取或者写入数据。

**2 构建基本验证环境**：  
我们可以将验证环境大致分为五个部分：  
<img src="env.png" alt="env" width="800" height="600">
> **1. Testcase Driver**：负责由用例产生相应的信号驱动  
> **2. Monitor**：监听信号，判断功能是否被覆盖以及功能是否正确  
> **3. Ref Cache**：一个简单的参考模型  
> **4. Memory/MMIO Ram**：外围设备的模拟，用于模拟相应cache的请求  
> **5. Nutshell Cache Dut**：由Picker生成的DUT  

此外，您可能还需要对DUT的接口做进一步封装以实现更方便的读写请求操作，具体可以参考[Nutshll cachewrapper](https://github.com/yzcccccccccc/XS-MLVP-NutShellCache/blob/master/UT_Cache/util/cachewrapper.py)。

**3 功能点与测试点分解**：  
果壳cache可以响应MMIO请求，进一步分解可以得到一下测试点：  
> **测试点1**：MMIO请求会被转发到MMIO端口上  
> **测试点2**：cache响应MMIO请求时，不会发出突发传输（Burst Transfer）的请求  
> **测试点3**：cache响应MMIO请求时，会阻塞流水线


**4 构造测试用例**：
测试用例的构造是简单的，已知通过[创建DUT](/zh-cn/docs/basic/create_dut)得到的Nutshell cache的MMIO地址范围是`0x30000000`~`0x7fffffff`，则我们只需访问这段内存区间，应当就能获得MMIO的预期结果。需要注意的是，为了触发阻塞流水线的测试点，您可能需要连续地发起请求。  
以下是一个简单的测试用例：  
```python
# import CacheWrapper here

def mmio_test(cache: CacheWrapper):
	mmio_lb	= 0x30000000
	mmio_rb	= 0x30001000
	
	print("\n[MMIO Test]: Start MMIO Serial Test")
	for addr in range(mmio_lb, mmio_rb, 16):
		addr &= ~(0xf)
		addr1 = addr
		addr2 = addr + 4
		addr3 = addr + 8

		cache.trigger_read_req(addr1)
		cache.trigger_read_req(addr2)
		cache.trigger_read_req(addr3)

		cache.recv()
		cache.recv()
		cache.recv()
		
	print("[MMIO Test]: Finish MMIO Serial Test")
```  

**5 收集测试结果**：  
```python
'''
    In tb_cache.py
'''

# import packages here

class TestCache():
    def setup_class(self):
        color.print_blue("\nCache Test Start")

        self.dut = DUTCache("libDPICache.so")
        self.dut.init_clock("clock")

        # Init here
        # ...

        self.testlist = ["mmio_serial"]
    
    def teardown_class(self):
        self.dut.finalize()
        color.print_blue("\nCache Test End")

    def __reset(self):
        # Reset cache and devices
            
    # MMIO Test
    def test_mmio(self):
        if ("mmio_serial" in self.testlist):
            # Run test
            from ..test.test_mmio import mmio_test
            mmio_test(self.cache, self.ref_cache)
        else:
            print("\nmmio test is not included")

    def run(self):
        self.setup_class()
        
        # test
        self.test_mmio()

        self.teardown_class()
    pass

if __name__ == "__main__":
	tb = TestCache()
	tb.run()

```
运行：
```bash
    python3 tb_cache.py
```
以上仅为大致的运行流程，具体可以参考：[Nutshell Cache Verify](https://github.com/yzcccccccccc/XS-MLVP-NutShellCache)。


**6 评估运行结果**  
运行结束之后可以得到以下数据：  
行覆盖率：  
<img src="line_cov.png" alt="line_cov" width="800" height="600">

功能覆盖率：  
<img src="func_cov.png" alt="func_cov" width="400" height="300">

可以看到预设的MMIO功能均被覆盖且被正确触发。
