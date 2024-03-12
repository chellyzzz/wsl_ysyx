#include "Vtop.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <common.h>
#include <isa.h>

void init_monitor(int, char *[]);
bool difftest_check();
void difftest_step();
void print_regs();
void sdb_mainloop(VerilatedContext* contextp_sdb, Vtop* top_sdb, VerilatedVcdC* vcd_sdb);

bool rst_n_sync = false; // read from rtl by dpi-c.

VerilatedContext* contextp = new VerilatedContext;  
Vtop* top =new Vtop{contextp};  
VerilatedVcdC* vcd = new VerilatedVcdC;


void init_trace(){
    Verilated::traceEverOn(true);
    top->trace(vcd, 0);
    vcd->open("build/wave.vcd"); // 设置输出的文件
    top->i_rst_n = !0;
    top->clk = 0;
    top->eval();
    contextp->timeInc(1);
    vcd->dump(contextp->time());
    top->clk = 1;
    top->eval();
    contextp->timeInc(1);
    vcd->dump(contextp->time());
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
    // while (!contextp->gotFinish())
    // {
    // top->clk = 0;
    // top->eval();
    // contextp->timeInc(1);
    // vcd->dump(contextp->time());
    // top->clk = 1;
    // top->eval();
    // contextp->timeInc(1);
    // vcd->dump(contextp->time());     
    // }
    // end_wave();    
    // return 0;
    sdb_mainloop(contextp, top, vcd);
    end_wave();
    return 0;
}

