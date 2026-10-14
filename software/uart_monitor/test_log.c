#include "spw_log.h"
#include <assert.h>
#include <stdio.h>
#include <string.h>
struct mock { unsigned pops, snapshots, lines; int bad_id; char output[4096]; };
static uint32_t read_mock(void *context, uint32_t offset)
{
    struct mock *m=context;
    if (offset==0) { ++m->snapshots; return m->bad_id ? 0 : 0x53505731u; }
    if (offset==4) return 4;
    if (offset==8) return 0x010c;
    if (offset==12) return 0x12345678;
    if (offset>=0x20 && offset<=0x44) return (offset-0x20)/4+100;
    if (offset==0x108) return 3-m->pops;
    if (offset==0x100) { ++m->pops; return 0x010c0000u | (1u<<(m->pops-1)); }
    if (offset==0x104) return 0x80u+m->pops;
    if (offset==0x10c) return 7;
    assert(0); return 0;
}
static void output_mock(void *context, const char *line)
{
    struct mock *m=context;
    assert(strlen(m->output)+strlen(line)<sizeof m->output);
    strcat(m->output,line); ++m->lines;
}
int main(void)
{
    struct mock m={0};
    assert(spw_log_snapshot(read_mock,output_mock,&m)==0);
    assert(m.snapshots==1 && m.lines==2);
    assert(strstr(m.output,"running=1") && strstr(m.output,"tx_queued=100"));
    assert(strstr(m.output,"reconnect=109 lost_events=7\r\n"));
    assert(spw_log_events(read_mock,output_mock,&m,2)==2 && m.pops==2);
    assert(strstr(m.output,"ticks=00000081 status=0001") && strstr(m.output,"ticks=00000082 status=0002"));
    assert(spw_log_events(read_mock,output_mock,&m,8)==1 && m.pops==3);
    assert(spw_log_events(read_mock,output_mock,&m,8)==0);
    m.bad_id=1;
    assert(spw_log_snapshot(read_mock,output_mock,&m)==-1);
    assert(strstr(m.output,"ERROR telemetry identity mismatch"));
    puts("TEST_PASS: UART log formatting, counter mapping, bounded FIFO drain, timestamp pairing and identity rejection");
    return 0;
}
