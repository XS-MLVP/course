---
title: 创建DUT
description:  以果壳cache为例，介绍如何创建基于chisel的DUT
categories: [示例项目, 学习材料]
tags: [examples, docs]
weight: 3
---

{{% pageinfo %}}
以果壳cache为例，介绍如何创建基于Chisel的DUT
{{% /pageinfo %}}

在本文档中，DUT（Design Under Test）是指在芯片验证过程中，被验证的对象电路或系统。DUT是验证的主体，在基于picker工具创建DUT时，需要考虑被测对象的功能、性能要求和验证目标，例如是需要更快的执行速度，还是需要更详细的测试信息。通常情况下DUT，即RTL编写的源码，与外围环境一起构成验证环境（test_env），然后基于该验证环境编写测试用例。在本项目中，DUT是需要测试的Python模块，需要通过RTL进行转换。传统的RTL语言包括Verilog、System Verilog、VHDL等，然而作为新兴的RTL设计语言，Chisel（[https://www.chisel-lang.org/](https://www.chisel-lang.org/)）也以其面向对象的特征和便捷性，逐渐在RTL设计中扮演越来越重要的角色。本章以[果壳处理器-NutShell](https://github.com/OSCPU/NutShell)中的cache源代码到Python模块的转换为例进行介绍如何创建DUT。


## Chisel与果壳
准确来说，Chisel是基于Scala语言的高级硬件构造（HCL）语言。传统HDL是描述电路，而HCL则是生成电路，更加抽象和高级。同时Chisel中提供的Stage包则可以将HCL设计转化成Verilog、System Verilog等传统的HDL语言设计。配合上Mill、Sbt等Scala工具则可以实现自动化的开发。

果壳是使用 Chisel 语言模块化设计的、基于 RISC-V RV64 开放指令集的顺序单发射处理器实现。果壳更详细的介绍请参考链接：[https://oscpu.github.io/NutShell-doc/](https://oscpu.github.io/NutShell-doc/)


## 果壳 cache

果壳cache（Nutshell Cache）是果壳处理器中使用的缓存模块。其采用三级流水设计，当第三级流水检出当前请求为MMIO或者发生重填（refill）时，会阻塞流水线。同时，果壳cache采用可定制的模块化设计，通过改变参数可以生成存储空间大小不同的一级cache（L1 Cache）或者二级cache（L2 Cache）。此外，果壳cache留有一致性（coherence）接口，可以处理一致性相关的请求。

![nt_cache](nt_cache.png)

## Chisel 转 Verilog

Chisel中的`stage`库可以帮助由Chisel代码生成Verilog、System Verilog等传统的HDL代码。以下将简单介绍如何由基于Chisel的cache实现转换成对应的Verilog电路描述。

### 初始化果壳环境
首先从源仓库下载整个果壳源代码，并进行初始化：

``` bash
mkdir cache-ut
cd cache-ut
git clone https://github.com/OSCPU/NutShell.git
cd NutShell && git checkout 97a025d
make init
```

### 创建scala编译配置
在cache-ut目录下创建build.sc，其中内容如下：
```scala
import $file.NutShell.build
import mill._, scalalib._
import coursier.maven.MavenRepository
import mill.scalalib.TestModule._

// 指定Nutshell的依赖
object difftest extends NutShell.build.CommonNS {
  override def millSourcePath = os.pwd / "NutShell" / "difftest"
}

// Nutshell 配置
object NtShell extends NutShell.build.CommonNS with NutShell.build.HasChiselTests {
  override def millSourcePath = os.pwd / "NutShell"
  override def moduleDeps = super.moduleDeps ++ Seq(
        difftest,
  )
}

// UT环境配置
object ut extends NutShell.build.CommonNS with ScalaTest{
    override def millSourcePath = os.pwd
    override def moduleDeps = super.moduleDeps ++ Seq(
        NtShell
    )
}

```


### 实例化 cache
创建好配置信息后，按照scala规范，创建src/main/scala源代码目录。之后，就可以在源码目录中创建nut_cache.scala，利用如下代码实例化Cache并转换成Verilog代码：

```scala
package ut_nutshell

import chisel3._
import chisel3.util._
import nutcore._
import top._
import chisel3.stage._

object CacheMain extends App {
  (new ChiselStage).execute(args, Seq(
      ChiselGeneratorAnnotation(() => new Cache()(CacheConfig(ro = false, name = "tcache", userBits = 16)))
    ))
}
```

### 生成RTL
完成上述所有文件的创建后（build.sc，src/main/scala/nut_cache.scala），在cache-ut目录下执行如下命令：

```bash
mkdir build
mill --no-server -d ut.runMain ut_nutshell.CacheMain --target-dir build --output-file Cache
```

注：mill环境的配置请参考 [https://mill-build.org/mill/cli/installation-ide.html](https://mill-build.org/mill/cli/installation-ide.html)

上述命令成功执行完成后，会在build目录下生成verilog文件：Cache.v。之后就可以通过picker工具进行Cache.v到 Python模块的转换。除去chisel外，其他HCL语言几乎都能生成对应的 RTL代码，因此上述基本流程也适用于其他HCL。


### DUT编译

一般情况下，如果需要DUT生成波形、覆盖率等会导致DUT的执行速度变慢，因此在通过picker工具生成python模块时会根据多种配置进行生成：（1）关闭所有debug信息；（2）开启波形；（3）开启代码行覆盖率。其中第一种配置的目标是快速构建环境，进行回归测试等；第二种配置用于分析具体错误，时序等；第三种用于提升覆盖率。
