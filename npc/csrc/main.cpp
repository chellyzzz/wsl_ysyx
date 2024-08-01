#include <VysyxSoCFull.h>
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <common.h>
#include <isa.h>
#include <memory/paddr.h>

#ifdef CONFIG_NVBOARD
#include <nvboard.h>
void nvboard_bind_all_pins(VysyxSoCFull* top);
#endif

void init_monitor(int, char *[]);
int sdb_mainloop(VerilatedContext* contextp_sdb, VysyxSoCFull* top_sdb, VerilatedVcdC* vcd_sdb);

VerilatedContext* contextp = new VerilatedContext;  
VysyxSoCFull* top =new VysyxSoCFull{contextp};  
VerilatedVcdC* vcd = new VerilatedVcdC;

void init_trace(){
    #ifdef CONFIG_WAVE
    Verilated::traceEverOn(true);
    top->trace(vcd, 0);
    vcd->open("build/wave.vcd"); // 设置输出的文件
    #endif
    top->reset = 1;
    top->clock = 0;
    top->eval();
    #ifdef CONFIG_NVBOARD
    nvboard_update();
    #endif
    #ifdef CONFIG_WAVE
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    #endif
    top->clock = 1;
    top->eval();
    #ifdef CONFIG_NVBOARD
    nvboard_update();
    #endif
    #ifdef CONFIG_WAVE
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    #endif
}

void end_wave(){
    top->final();
    vcd->close();
    delete vcd;
    delete top;
    delete contextp;
}

int main(int argc,char *argv[]){
    if (false && argc && argv){
        printf("sorry but no argc\n;");
    }
    Verilated::commandArgs(argc,argv);
    #ifdef CONFIG_NVBOARD
    nvboard_bind_all_pins(top);
    nvboard_init();
    #endif
    init_trace();

    init_monitor(argc, argv);
    int good = sdb_mainloop(contextp, top, vcd);
    end_wave();
    return !good;
}

