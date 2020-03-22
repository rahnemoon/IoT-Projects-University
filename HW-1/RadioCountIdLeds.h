#ifndef LOG
#define LOG 0 // 1 for COOJA Log and 2 for GDB Log
#endif

#ifndef RADIO_COUNT_ID_LEDS_H
#define RADIO_COUNT_ID_LEDS_H

typedef nx_struct RadioCountIdMsg {
  nx_uint8_t nodeId;
  nx_uint16_t counter;
} RadioCountIdMsg_t;

enum {
  AM_RADIO_COUNT_MSG = 6,
  TIMER_PERIOD_MILLI_1 = 1000,
  TIMER_PERIOD_MILLI_2 = 333,
  TIMER_PERIOD_MILLI_3 = 200,
  TIMER_PERIOD_MILLI_MODE_10 = 2000,
};

#endif
