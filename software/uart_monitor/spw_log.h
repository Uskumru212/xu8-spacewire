#ifndef SPW_LOG_H
#define SPW_LOG_H
#include <stdint.h>
typedef uint32_t (*spw_read_fn)(void *context, uint32_t offset);
typedef void (*spw_output_fn)(void *context, const char *line);
/* Exclusive reader required: FIFO pop and timestamp reads are a pair. */
int spw_log_snapshot(spw_read_fn read, spw_output_fn output, void *context);
unsigned spw_log_events(spw_read_fn read, spw_output_fn output, void *context, unsigned budget);
#endif
