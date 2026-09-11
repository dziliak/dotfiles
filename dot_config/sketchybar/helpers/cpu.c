// Aggregate CPU ticks from macOS, rather than process-lifetime ps averages.
#include <inttypes.h>
#include <mach/mach.h>
#include <stdint.h>
#include <stdio.h>
#include <time.h>

int main(void) {
  host_cpu_load_info_data_t cpu;
  mach_msg_type_number_t count = HOST_CPU_LOAD_INFO_COUNT;
  mach_port_t host = mach_host_self();
  kern_return_t result = host_statistics(host, HOST_CPU_LOAD_INFO,
                                         (host_info_t)&cpu, &count);
  mach_port_deallocate(mach_task_self(), host);
  if (result != KERN_SUCCESS) {
    fprintf(stderr, "CPU counters: %s\n", mach_error_string(result));
    return 1;
  }

  uint64_t busy = (uint64_t)cpu.cpu_ticks[CPU_STATE_USER]
                + cpu.cpu_ticks[CPU_STATE_SYSTEM]
                + cpu.cpu_ticks[CPU_STATE_NICE];
  printf("%" PRIu64 " %" PRIu64 " %lld\n", busy,
         (uint64_t)cpu.cpu_ticks[CPU_STATE_IDLE], (long long)time(NULL));
  return 0;
}
