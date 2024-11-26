---
title: CoupledL2
description: 用C++、Java和Python简单验证香山L2 Cache的案例
categories: [教程]
tags: [docs]
weight: 3
---

`CoupledL2`是一个非阻塞的[L2 Cache](https://github.com/OpenXiangShan/CoupledL2)。

下面的代码会对`CoupledL2`进行简单的验证，并使用数组作为参考模型，验证过程如下：

1. 生成随机的地址`addr`、执行`AcquireBlock`，请求读取`addr`的数据。
2. 执行`GrantData`，接收`DUT`响应的数据。
3. 把接收到的数据和参考模型的内容进行比较，验证行为是否一致。
4. 执行`GrantAck`，响应`DUT`。
5. 执行`ReleaseData`，向`DUT`请求在`addr`写入随机数据`data`。
6. 同步参考模型，把`addr`的数据更新为`data`。
7. 执行`ReleaseAck`，接收`DUT`的写入响应。

上述步骤会重复4000次。

验证代码：

{{<lang-group languages="cpp,java,python">}}

{{<lang lang="cpp" show="true">}}
#include "UT_CoupledL2.hpp"
using TLDataArray = std::array<uint64_t, 2>;

enum class OpcodeA : uint32_t {
  PutFullData = 0x0,
  PutPartialData = 0x1,
  ArithmeticData = 0x2,
  LogicalData = 0x3,
  Get = 0x4,
  Hint = 0x5,
  AcquireBlock = 0x6,
  AcquirePerm = 0x7,
};

enum class OpcodeB : uint32_t { ProbeBlock = 0x6, ProbePerm = 0x7 };

enum class OpcodeC : uint32_t { ProbeAck = 0x4, ProbeAckData = 0x5, Release = 0x6, ReleaseData = 0x7 };

enum class OpcodeD : uint32_t { AccessAck, AccessAckData, HintAck, Grant = 0x4, GrantData = 0x5, ReleaseAck = 0x6 };

enum class OpcodeE : uint32_t { GrantAck = 0x4 };

constexpr std::initializer_list<const char *> ARGS = {"+verilator+rand+reset+0"};
auto dut = UTCoupledL2(ARGS);
auto &clk = dut.xclock;

void sendA(OpcodeA opcode, uint32_t size, uint32_t address) {
  const auto &valid = dut.master_port_0_0_a_valid;
  const auto &ready = dut.master_port_0_0_a_ready;
  while (ready.value == 0x0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_a_bits_opcode.value = opcode;
  dut.master_port_0_0_a_bits_size.value = size;
  dut.master_port_0_0_a_bits_address.value = address;
  clk.Step();
  valid.value = 0;
}

void getB() {
  assert(false);
  const auto &valid = dut.master_port_0_0_b_valid;
  const auto &ready = dut.master_port_0_0_b_ready;
  ready.value = 1;
  while (valid.value == 0)
    clk.Step();
  dut.master_port_0_0_b_bits_opcode = 0x0;
  dut.master_port_0_0_b_bits_param = 0x0;
  dut.master_port_0_0_b_bits_size = 0x0;
  dut.master_port_0_0_b_bits_source = 0x0;
  dut.master_port_0_0_b_bits_address = 0x0;
  dut.master_port_0_0_b_bits_mask = 0x0;
  dut.master_port_0_0_b_bits_data = 0x0;
  dut.master_port_0_0_b_bits_corrupt = 0x0;
  clk.Step();
  ready.value = 0;
}

void sendC(OpcodeC opcode, uint32_t size, uint32_t address, uint64_t data) {
  const auto &valid = dut.master_port_0_0_c_valid;
  const auto &ready = dut.master_port_0_0_c_ready;

  while (ready.value == 0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_c_bits_opcode.value = opcode;
  dut.master_port_0_0_c_bits_size.value = size;
  dut.master_port_0_0_c_bits_address.value = address;
  dut.master_port_0_0_c_bits_data.value = data;
  clk.Step();
  valid.value = 0;
}

void getD() {
  const auto &valid = dut.master_port_0_0_d_valid;
  const auto &ready = dut.master_port_0_0_d_ready;
  ready.value = 1;
  clk.Step();
  while (valid.value == 0) clk.Step();
  ready.value = 0;
}

void sendE(uint32_t sink) {
  const auto &valid = dut.master_port_0_0_e_valid;
  const auto &ready = dut.master_port_0_0_e_ready;
  while (ready.value == 0) clk.Step();
  valid.value = 1;
  dut.master_port_0_0_e_bits_sink.value = sink;
  clk.Step();
  valid.value = 0;
}

void AcquireBlock(uint32_t address) { sendA(OpcodeA::AcquireBlock, 0x6, address); }

void GrantData(TLDataArray &r_data) {
  const auto &opcode = dut.master_port_0_0_d_bits_opcode;
  const auto &data = dut.master_port_0_0_d_bits_data;

  for (int i = 0; i < 2; i++) {
    do { getD(); } while (opcode.value != OpcodeD::GrantData);
    r_data[i] = data.value;
  }
}

void GrantAck(uint32_t sink) { sendE(sink); }

void ReleaseData(uint32_t address, const TLDataArray &data) {
  for (int i = 0; i < 2; i++)
    sendC(OpcodeC::ReleaseData, 0x6, address, data[i]);
}

void ReleaseAck() {
  const auto &opcode = dut.master_port_0_0_d_bits_opcode;
  do { getD(); } while (opcode.value != OpcodeD::ReleaseAck);
}

int main() {
  TLDataArray ref_data[16] = {};
  /* Random generator */
  std::random_device rd;
  std::mt19937_64 gen_rand(rd());
  std::uniform_int_distribution<uint32_t> distrib(0, 0xf - 1);

  /* DUT init */
  dut.InitClock("clock");
  dut.reset.SetWriteMode(xspcomm::WriteMode::Imme);
  dut.reset.value = 1;
  clk.Step();
  dut.reset.value = 0;
  for (int i = 0; i < 100; i++) clk.Step();

  /* Test loop */
  for (int test_loop = 0; test_loop < 4000; test_loop++) {
    uint32_t d_sink;
    TLDataArray data{}, r_data{};
    /* Generate random */
    const auto address = distrib(gen_rand) << 6;
    for (auto &i : data)
      i = gen_rand();

    printf("[CoupledL2 Test\t%d]: At address(0x%03x), ", test_loop + 1, address);
    /* Read */
    AcquireBlock(address);
    GrantData(r_data);

    // Print read result
    printf("Read: ");
    for (const auto &x : r_data)
      printf("%08lx", x);

    d_sink = dut.master_port_0_0_d_bits_sink.value;
    assert ((r_data == ref_data[address >> 6]) && "Read Failed");
    GrantAck(d_sink);

    /* Write */
    ReleaseData(address, data);
    ref_data[address >> 6] = data;
    ReleaseAck();

    // Print write data
    printf(", Write: ");
    for (const auto &x : data)
      printf("%08lx", x);
    printf(".\n");
  }

  return 0;
}
{{</lang>}}


{{<lang lang="java">}}
import com.ut.UT_CoupledL2;
import com.xspcomm.WriteMode;

import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.math.BigInteger;
import java.util.Arrays;
import java.util.Random;
import java.util.random.RandomGenerator;

class Opcode {
    public enum A {
        PutFullData(0x0),
        PutPartialData(0x1),
        ArithmeticData(0x2),
        LogicalData(0x3),
        Get(0x4),
        Hint(0x5),
        AcquireBlock(0x6),
        AcquirePerm(0x7);

        private final int value;
    
        A(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum B {
        ProbeBlock(0x6), ProbePerm(0x7);
    
        private final int value;
    
        B(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum C {
        ProbeAck(0x4), ProbeAckData(0x5), Release(0x6), ReleaseData(0x7);
    
        private final int value;
    
        C(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum D {
        AccessAck(0x0), AccessAckData(0x1), HintAck(0x2), Grant(0x4), GrantData(0x5), ReleaseAck(0x6);
    
        private final int value;
    
        D(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
    
    public enum E {
        GrantAck(0x4);
    
        private final int value;
    
        E(int value) {
            this.value = value;
        }
    
        public int getValue() {
            return value;
        }
    }
}

public class TestCoupledL2 {
    static PrintWriter pwOut = new PrintWriter(new BufferedWriter(new OutputStreamWriter(System.out)));
    static UT_CoupledL2 dut;

    static void sendA(int opcode, int size, int address) {
        var valid = dut.master_port_0_0_a_valid;
        var ready = dut.master_port_0_0_a_ready;
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_a_bits_opcode.Set(opcode);
        dut.master_port_0_0_a_bits_size.Set(size);
        dut.master_port_0_0_a_bits_address.Set(address);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void getB() {
        var valid = dut.master_port_0_0_b_valid;
        var ready = dut.master_port_0_0_b_ready;
        ready.Set(1);
        while (!valid.B()) dut.xclock.Step();
        ready.Set(0);
    }
    
    static void sendC(int opcode, int size, int address, long data) {
        var valid = dut.master_port_0_0_c_valid;
        var ready = dut.master_port_0_0_c_ready;
    
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_c_bits_opcode.Set(opcode);
        dut.master_port_0_0_c_bits_size.Set(size);
        dut.master_port_0_0_c_bits_address.Set(address);
        dut.master_port_0_0_c_bits_data.Set(data);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void getD() {
        var valid = dut.master_port_0_0_d_valid;
        var ready = dut.master_port_0_0_d_ready;
        ready.Set(1);
        dut.xclock.Step();
        while (!valid.B()) dut.xclock.Step();
        ready.Set(0);
    }
    
    static void sendE(int sink) {
        var valid = dut.master_port_0_0_e_valid;
        var ready = dut.master_port_0_0_e_ready;
        while (!ready.B()) dut.xclock.Step();
        valid.Set(1);
        dut.master_port_0_0_e_bits_sink.Set(sink);
        dut.xclock.Step();
        valid.Set(0);
    }
    
    static void AcquireBlock(int address) {
        sendA(Opcode.A.AcquireBlock.getValue(), 0x6, address);
    }
    
    static BigInteger GrantData() {
        var opcode = dut.master_port_0_0_d_bits_opcode;
        var data = dut.master_port_0_0_d_bits_data;
    
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.GrantData.getValue());
        var r_data = data.U64().shiftLeft(64);
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.GrantData.getValue());
        return r_data.or(data.U64());
    }
    
    static void GrantAck(int sink) {
        sendE(sink);
    }
    
    static void ReleaseData(int address, BigInteger data) {
        sendC(Opcode.C.ReleaseData.getValue(), 0x6, address, data.longValue());
        sendC(Opcode.C.ReleaseData.getValue(), 0x6, address, data.shiftRight(64).longValue());
    }
    
    static void ReleaseAck() {
        var opcode = dut.master_port_0_0_d_bits_opcode;
        do {
            getD();
        } while (opcode.Get().intValue() != Opcode.D.ReleaseAck.getValue());
    }
    
    public static void main(String[] args) throws IOException {
        /* Random Generator */
        var gen_rand = RandomGenerator.getDefault();
        /* DUT init */
        final String[] ARGS = {"+verilator+rand+reset+0"};
        dut = new UT_CoupledL2(ARGS);
        dut.InitClock("clock");
        dut.reset.SetWriteMode(WriteMode.Imme);
        dut.reset.Set(1);
        dut.xclock.Step();
        dut.reset.Set(0);
        for (int i = 0; i < 100; i++) dut.xclock.Step();
        dut.xclock.Step();
    
        /* Ref */
        BigInteger[] ref_data = new BigInteger[16];
        Arrays.fill(ref_data, BigInteger.ZERO);
    
        /* Test loop */
        for (int test_loop = 0; test_loop < 4000; test_loop++) {
            var address = gen_rand.nextInt(0xf) << 6;
            var data = new BigInteger(128, Random.from(gen_rand));
    
            pwOut.print("[CoupledL2 Test%d]: At address(%#03x), ".formatted(test_loop + 1, address));
            /* Read */
            AcquireBlock(address);
            var r_data = GrantData();
            assert (r_data.equals(ref_data[address >> 6]));
    
            var sink = dut.master_port_0_0_d_bits_sink.Get().intValue();
            GrantAck(sink);


            /* Write */
            ReleaseData(address, data);
            ref_data[address >> 6] = data;
            ReleaseAck();
    
            pwOut.println("Read: %s, Write: %s".formatted(r_data.toString(), data.toString()));
            pwOut.flush();
        }
    }
}

{{</lang>}}

{{<lang lang="python">}}
################ bundle.py ################
from toffee import Bundle, Signals, Signal

class DecoupledBundle(Bundle):
    ready, valid = Signals(2)

class TileLinkBundleA(DecoupledBundle):
    opcode, param, size, source, address, user_alias, mask, data, corrupt = Signals(9)

class TileLinkBundleB(DecoupledBundle):
    opcode, param, size, source, address, mask, data, corrupt = Signals(8)

class TileLinkBundleC(DecoupledBundle):
    opcode, param, size, source, address, user_alias, data, corrupt = Signals(8)

class TileLinkBundleD(DecoupledBundle):
    opcode, param, size, source, sink, denied, data, corrupt = Signals(8)

class TileLinkBundleE(DecoupledBundle):
    sink = Signal()

class TileLinkBundle(Bundle):
    a = TileLinkBundleA.from_regex(r"a_(?:(valid|ready)|bits_(.*))")
    b = TileLinkBundleB.from_regex(r"b_(?:(valid|ready)|bits_(.*))")
    c = TileLinkBundleC.from_regex(r"c_(?:(valid|ready)|bits_(.*))")
    d = TileLinkBundleD.from_regex(r"d_(?:(valid|ready)|bits_(.*))")
    e = TileLinkBundleE.from_regex(r"e_(?:(valid|ready)|bits_(.*))")
{{</lang>}}



{{<lang lang="python">}}
################ agent.py ################
from toffee import Agent, driver_method
from toffee.triggers import Value
from bundle import TileLinkBundle


class TilelinkOPCodes:
    class A:
        PutFullData = 0x0
        PutPartialData = 0x1
        ArithmeticData = 0x2
        LogicalData = 0x3
        Get = 0x4
        Hint = 0x5
        AcquireBlock = 0x6
        AcquirePerm = 0x7

    class B:
        Probe = 0x8

    class C:
        ProbeAck = 0x4
        ProbeAckData = 0x5
        Release = 0x6
        ReleaseData = 0x7

    class D:
        AccessAck = 0x0
        AccessAckData = 0x1
        HintAck = 0x2
        Grant = 0x4
        GrantData = 0x5
        ReleaseAck = 0x6

    class E:
        GrantAck = 0x4


class TileLinkAgent(Agent):
    def __init__(self, tlbundle: TileLinkBundle):
        super().__init__(tlbundle.step)

        self.tlbundle = tlbundle

    @driver_method()
    async def put_a(self, dict):
        dict["valid"] = 1
        self.tlbundle.a.assign(dict)
        await Value(self.tlbundle.a.ready, 1)
        self.tlbundle.a.valid.value = 0

    @driver_method()
    async def get_d(self):
        self.tlbundle.d.ready.value = 1
        await Value(self.tlbundle.d.valid, 1)
        result = self.tlbundle.d.as_dict()
        self.tlbundle.d.ready.value = 0
        return result

    @driver_method()
    async def get_b(self):
        self.tlbundle.b.ready.value = 1
        await Value(self.tlbundle.b.valid, 1)
        result = self.tlbundle.b.as_dict()
        self.tlbundle.b.ready.value = 0
        return result

    @driver_method()
    async def put_c(self, dict):
        dict["valid"] = 1
        self.tlbundle.c.assign(dict)
        await Value(self.tlbundle.c.ready, 1)
        self.tlbundle.c.valid.value = 0

    @driver_method()
    async def put_e(self, dict):
        dict["valid"] = 1
        self.tlbundle.e.assign(dict)
        await Value(self.tlbundle.e.ready, 1)
        self.tlbundle.e.valid.value = 0

    ################################

    async def aquire_block(self, address):
        await self.put_a(
            {
                "*": 0,
                "size": 0x6,
                "opcode": TilelinkOPCodes.A.AcquireBlock,
                "address": address,
            }
        )

        data = 0x0
        for i in range(2):
            ret = await self.get_d()
            while ret["opcode"] != TilelinkOPCodes.D.GrantData:
                ret = await self.get_d()
            data = (ret["data"] << (256 * i)) | data

        await self.put_e({"sink": ret["sink"]})

        return data

    async def release_data(self, address, data):
        for _ in range(2):
            await self.put_c(
                {
                    "*": 0,
                    "size": 0x6,
                    "opcode": TilelinkOPCodes.C.ReleaseData,
                    "address": address,
                    "data": data % (2**256),
                }
            )
            data = data >> 256

        x = await self.get_d()
        while x["opcode"] != TilelinkOPCodes.D.ReleaseAck:
            x = await self.get_d()
{{</lang>}}
{{<lang lang="python">}}
################ test.py ################
import toffee
import random
from toffee.triggers import ClockCycles
from UT_CoupledL2 import DUTCoupledL2
from bundle import TileLinkBundle
from agent import TileLinkAgent


async def test_top(dut: DUTCoupledL2):
    toffee.start_clock(dut)

    dut.reset.value = 1
    await ClockCycles(dut, 100)
    dut.reset.value = 0

    tlbundle = TileLinkBundle.from_prefix("master_port_0_0_").bind(dut)
    tlbundle.set_all(0)
    tlagent = TileLinkAgent(tlbundle)

    await ClockCycles(dut, 20)
    ref_data = [0] * 0x10

    for _ in range(4000):
        # Read
        address = random.randint(0, 0xF) << 6
        r_data = await tlagent.aquire_block(address)
        print(f"Read {address} = {hex(r_data)}")
        assert r_data == ref_data[address >> 6]

        # Write
        send_data = random.randint(0, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        await tlagent.release_data(address, send_data)
        ref_data[address >> 6] = send_data
        print(f"Write {address} = {hex(send_data)}")


if __name__ == "__main__":
    toffee.setup_logging(toffee.INFO)
    dut = DUTCoupledL2(["+verilator+rand+reset+0"])
    dut.InitClock("clock")
    dut.reset.AsImmWrite()

    toffee.run(test_top(dut))

    dut.Finish()
{{</lang>}}

{{</lang-group>}}
