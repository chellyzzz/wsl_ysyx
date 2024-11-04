#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <common.h>
#include <isa.h>

void init_monitor(int, char *[]);
int sdb_mainloop(VerilatedContext* contextp_sdb, Vtop* top_sdb, VerilatedVcdC* vcd_sdb);

VerilatedContext* contextp = new VerilatedContext;  
Vtop* top =new Vtop{contextp};  
VerilatedVcdC* vcd = new VerilatedVcdC;


void init_trace(){
    #ifdef CONFIG_WAVE
    Verilated::traceEverOn(true);
    top->trace(vcd, 0);
    vcd->open("build/wave.vcd"); // 设置输出的文件
    #endif
    top->i_rst_n = !0;
    top->clk = 0;
    top->eval();
    #ifdef CONFIG_WAVE
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    #endif
    top->clk = 1;
    top->eval();
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
    init_trace();
    init_monitor(argc, argv);

    int good = sdb_mainloop(contextp, top, vcd);
    end_wave();
    return !good;
}

