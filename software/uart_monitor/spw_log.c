#include "spw_log.h"
#include <stdio.h>

int spw_log_snapshot(spw_read_fn read, spw_output_fn output, void *context)
{
    char line[512];
    uint32_t c[10], status, control, ticks, lost;
    unsigned i;
    if (read(context, 0) != 0x53505731u) {
        output(context, "ERROR telemetry identity mismatch\r\n");
        return -1;
    }
    status = read(context, 4); control = read(context, 8); ticks = read(context, 12);
    for (i=0; i<10; ++i) c[i] = read(context, 0x20u+4u*i);
    lost = read(context, 0x10c);
    snprintf(line, sizeof line,
        "SNAP ticks=%08lx status=%04lx control=%04lx started=%u connecting=%u running=%u\r\n",
        (unsigned long)ticks, (unsigned long)status, (unsigned long)control,
        (unsigned)(status&1u), (unsigned)((status>>1)&1u), (unsigned)((status>>2)&1u));
    output(context, line);
    snprintf(line, sizeof line,
        "COUNT tx_queued=%lu tx_ends=%lu rx=%lu rx_ends=%lu rx_eep=%lu parity=%lu disconnect=%lu escape=%lu credit=%lu reconnect=%lu lost_events=%lu\r\n",
        (unsigned long)c[0], (unsigned long)c[1], (unsigned long)c[2], (unsigned long)c[3],
        (unsigned long)c[4], (unsigned long)c[5], (unsigned long)c[6], (unsigned long)c[7],
        (unsigned long)c[8], (unsigned long)c[9], (unsigned long)lost);
    output(context, line);
    return 0;
}

unsigned spw_log_events(spw_read_fn read, spw_output_fn output, void *context, unsigned budget)
{
    char line[192];
    unsigned n=0;
    while (n<budget && read(context, 0x108)!=0) {
        uint32_t event=read(context, 0x100); /* Pop exactly once. */
        uint32_t ticks=read(context, 0x104); /* Timestamp of that pop. */
        uint32_t s=event&0xffffu;
        snprintf(line, sizeof line,
            "EVENT ticks=%08lx status=%04lx control=%04lx started=%u connecting=%u running=%u disc=%u parity=%u escape=%u credit=%u\r\n",
            (unsigned long)ticks, (unsigned long)s, (unsigned long)(event>>16),
            (unsigned)(s&1u), (unsigned)((s>>1)&1u), (unsigned)((s>>2)&1u),
            (unsigned)((s>>4)&1u), (unsigned)((s>>5)&1u), (unsigned)((s>>6)&1u), (unsigned)((s>>7)&1u));
        output(context, line); ++n;
    }
    return n;
}
