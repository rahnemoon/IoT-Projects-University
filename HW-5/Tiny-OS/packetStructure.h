#ifndef LOG
#define LOG 0 // 1 for Log in COOJA
#endif

#ifndef PACKETSTRUCTURE_H
#define PACKETSTRUCTURE_H

typedef nx_struct msg_struc {
  nx_uint16_t value;
  nx_uint16_t topic;
} msg_struct_t;

enum{
AM_SEND_MSG = 6,
};

#endif
