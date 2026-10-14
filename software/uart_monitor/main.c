/* Standalone A53 application; requires generated XSA and standalone BSP.
 * Link into OCM, initialize the PS using generated psu_init, then start this app.
 * No Linux, DDR, filesystem, printf stdout routing, or flash update is required.
 */
#include "spw_log.h"
#include "xuartps.h"
#include "xuartps_hw.h"
#include "xparameters.h"
#include "xil_io.h"
#include "xil_mmu.h"
#include "sleep.h"

#define TELEMETRY_BASE ((UINTPTR)0xA0000000u)
#define UART0_BASE ((UINTPTR)0xff000000u)
static XUartPs uart;
static uint32_t read_register(void *unused, uint32_t offset)
{
    (void)unused;
    return Xil_In32(TELEMETRY_BASE + offset);
}
static void output_line(void *unused, const char *line)
{
    (void)unused;
    while (*line) XUartPs_SendByte(uart.Config.BaseAddress, (u8)*line++);
}
int main(void)
{
    XUartPs_Config *cfg;
    unsigned iteration=0;
#ifdef SDT
    cfg=XUartPs_LookupConfig(UART0_BASE);
#else
    cfg=XUartPs_LookupConfig(XPAR_XUARTPS_0_DEVICE_ID);
#endif
    if (!cfg || cfg->BaseAddress!=UART0_BASE) return 1;
    if (XUartPs_CfgInitialize(&uart,cfg,cfg->BaseAddress)!=XST_SUCCESS) return 2;
    {
        XUartPsFormat format = {115200, XUARTPS_FORMAT_8_BITS, XUARTPS_FORMAT_NO_PARITY, XUARTPS_FORMAT_1_STOP_BIT};
        if (XUartPs_SetDataFormat(&uart,&format)!=XST_SUCCESS) return 3;
    }
    XUartPs_SetOperMode(&uart,XUARTPS_OPER_MODE_NORMAL);
    output_line(0,"BOOT XU8 SpaceWire monitor; UART0 MIO38 RX / MIO39 TX; 115200 8N1\r\n");
    output_line(0,"INFO FPGA rail-enable outputs are high by design; voltage is not measured.\r\n");
    output_line(0,"INFO event ticks are 400 MHz cycles (wrap at 10.73741824 s); TX counts are local FIFO acceptance.\r\n");
    Xil_SetTlbAttributes(TELEMETRY_BASE, DEVICE_MEMORY);
    /* PL must be configured and its clock running before accessing this aperture. */
    if (spw_log_snapshot(read_register,output_line,0)!=0) return 4;
    for (;;) {
        spw_log_events(read_register,output_line,0,8);
        if (++iteration==100) {
            iteration=0;
            if (spw_log_snapshot(read_register,output_line,0)!=0) return 5;
        }
        usleep(10000);
    }
}
