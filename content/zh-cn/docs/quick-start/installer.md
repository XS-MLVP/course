---
title: 搭建验证环境
description: 安装相关依赖，**下载、构建并安装**对应的工具。
categories: [教程]
tags: [docs]
weight: 1
---

## 源码安装Picker工具

### 依赖安装

1.  [cmake](https://cmake.org/download/) ( >=3.11 )
2.  [gcc](https://gcc.gnu.org/) ( 支持c++20,至少为gcc版本10, **建议11及以上** )
3.  [python3](https://www.python.org/downloads/) ( >=3.8 )
4.  [verilator](https://verilator.org/guide/latest/install.html#git-quick-install) ( **==4.218** )
5.  [verible-verilog-format](https://github.com/chipsalliance/verible) ( >=0.0-3428-gcfcbb82b )
6.  [swig](http://www.swig.org/) ( >=**4.2.0**, 用于多语言支持 )

> 请注意，请确保`verible-verilog-format`等工具的路径已经添加到环境变量`$PATH`中，可以直接命令行调用。

### 下载源码

```bash
git clone https://github.com/XS-MLVP/picker.git
cd picker
make init
```

### 构建并安装

```bash
cd picker
make
# 可通过 make BUILD_XSPCOMM_SWIG=python,java,scala,golang 开启其他语言支持。
# 各语言需要自己的开发环境，需要自行配置，例如javac等
sudo -E make install
```

>默认的安装的目标路径是 /usr/local， 二进制文件被置于 /usr/local/bin，模板文件被置于 /usr/local/share/picker。
>安装时会自动安装 xspcomm基础库（https://github.com/XS-MLVP/xcomm），该基础库是用于封装 RTL 模块的基础类型，位于 /usr/local/lib/libxspcomm.so。 可能需要手动设置编译时的链接目录参数(-L)
>如果开启了Java等语言支持，还会安装 xspcomm 对应的多语言软件包。

### 安装测试

执行命令并检查输出：
>picker export --help

```bash
Export RTL Projects Sources as Software libraries such as C++/Python Usage: picker
export [OPTIONS] file

Positionals:
  file TEXT REQUIRED          DUT .v/.sv source file, contain the top module

Options:
  -h,--help                   Print this help message and exit
  --fs,--filelist TEXT        DUT .v/.sv source files, contain the top module, 
                              split by comma. Or use '*.txt' file  with one RTL 
                              file path per line to specify the file list
  --sim TEXT [verilator]      vcs or verilator as simulator, default is verilator
  --lang,--language TEXT:{python,cpp,java,scala,golang} [python] 
                              Build example project, default is python, choose 
                              cpp, java or python
  --sdir,--source_dir TEXT [/usr/local/share/picker/template] 
                              Template Files Dir, default is ${picker_install_path}/../picker/template
  --tdir,--target_dir TEXT [./picker_out] 
                              Codegen render files to target dir, default is ./picker_out
  --sname,--source_module_name TEXT
                              Pick the module in DUT .v file, default is the last 
                              module in the --fs marked file
  --tname,--target_module_name TEXT
                              Set the module name and file name of target DUT, 
                              default is the same as source. For example, --tname top, 
                              will generate UTtop.cpp and UTtop.hpp with UTtop class
  --internal TEXT             Exported internal signal config file, default is empty, 
                              means no internal pin
  -F,--frequency TEXT [100MHz] 
                              Set the frequency of the **only VCS** DUT, default 
                              is 100MHz, use Hz, KHz, MHz, GHz as unit
  -w,--wave_file_name TEXT    Wave file name, emtpy mean don't dump wave
  -c,--coverage               Enable coverage, default is not selected as OFF
  -V,--vflag TEXT             User defined simulator compile args, passthrough. 
                              Eg: '-v -x-assign=fast -Wall --trace' || '-C vcs -cc -f filelist.f'
  -C,--cflag TEXT             User defined gcc/clang compile command, passthrough. 
                              Eg:'-O3 -std=c++17 -I./include'
  --verbose                   Verbose mode
  -e,--example                Build example project, default is OFF
  --autobuild BOOLEAN [1]     Auto build the generated project, default is true
```

#### 参数解释

* `[file]`: 必需。DUT 的 Verilog 或 SystemVerilog 源文件，包含顶层模块
* `--filelist, -fs`: 可选。DUT 的 Verilog 或 SystemVerilog 源文件，逗号分隔。也可以使用 `*.txt` 文件，每行指定一个 RTL 文件路径，来指定文件列表。
* `--sim`: 可选。模拟器类型，可以是 vcs 或 verilator，默认是 verilator。
* `--language, --lang`: 可选。构建示例项目的语言，可以是 cpp 或 python，默认是 cpp。
* `--source_dir, -sdir`: 可选。模板文件目录，默认是 ${mcv_install_path}/../mcv/template。
* `--target_dir, -tdir`: 可选。渲染文件的目标目录，默认是 ./mcv_out。
* `--source_module_name, -sname`: 可选。在 DUT 的 Verilog 文件中选择模块，默认是  标记的文件中的最后一个模块。
* `--target_module_name, -tname`: 可选。设置目标 DUT 的模块名和文件名，默认与源相同。例如，-T top 将生成 UTtop.cpp 和 UTtop.hpp，并包含 UTtop 类。
* `--internal`: 可选。导出的内部信号配置文件，默认为空，表示没有内部引脚。
* `--frequency, -F`: 可选。设置 仅 VCS DUT 的频率，默认是 100MHz，可以使用 Hz、KHz、MHz、GHz 作为单位。
* `--wave_file_name, -w`: 可选。波形文件名，为空表示不导出波形。
* `--coverage, -c`: 可选。打开之后在测试完成后生成.dat的覆盖率数据。
* `--vflag, -V`: 可选。用户定义的模拟器编译参数，透传。例如：'-v -x-assign=fast -Wall --trace' 或 '-f filelist.f'。
* `--cflag, -C`: 可选。用户定义的 gcc/clang 编译参数，透传。例如：'-O3 -std=c++17 -I./include'。
* `--verbose, -v`: 可选。详细模式，保留生成的中间文件。
* `--example, -e`: 可选。构建示例项目，默认是 OFF。
* `--autobuild`: 可选。自动构建生成的项目，默认是true。
* `--help, -h`: 可选。打印使用帮助。

### 安装检测

可以通过\--check参数进行picker的安装检测，输出能够支持的编程语言，以及对于的依赖库位置。

>picker \--check

```bash
[OK ] Version: 0.1.0-develop-e3b38d5
[OK ] Exec path: /usr/local/bin/picker
[OK ] Template path: /usr/local/share/picker/template
[OK ] Support    Cpp (find: '/usr/local/share/picker/include' success)
[OK ] Support   Java (find: '/usr/local/share/picker/java/xspcomm-java.jar' success)
[Err] Support  Scala (find: 'scala/xspcomm-scala.jar' fail)
[OK ] Support Python (find: '/usr/local/share/picker/python' success)
[OK ] Support Golang (find: '/usr/local/share/picker/golang' success)
```

### 功能测试


```bash
cd picker # 进入项目根目录，即git clone的目录
bash example/Adder/release-verilator.sh --lang cpp
```

程序应当输出**类似**的内容，表示安装成功：

```bash
...
[cycle 114515] a=0xa9c430d2942bd554, b=0xe26feda874dac8b7, cin=0x0
DUT: sum=0x8c341e7b09069e0b, cout=0x1
REF: sum=0x8c341e7b09069e0b, cout=0x1
Test Passed, destory UTAdder
...
```

至此，picker工具安装完成。
