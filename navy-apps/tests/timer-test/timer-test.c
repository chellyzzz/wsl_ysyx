#include <stdio.h>
#include <assert.h>

uint32_t NDL_GetTicks();
#define TIME_GAP 10000

int main() {
    uint32_t gap = TIME_GAP;    
    int i = 0;
    while(i < 10) {
        // 获取当前时间
        uint32_t time = NDL_GetTicks();
        
        if (time >= gap) {
            // 输出一句话
            printf("10 seconds have passed!\n");
            gap += TIME_GAP;
            i += 1;
        }
        
    }
    printf("PASS!!!\n");

  return 0;
}
