
#ifndef SENSORSENDACK_H
#define SENSORSENDACK_H

typedef nx_struct msg_ack {
	nx_uint8_t type;
  nx_uint16_t value;
  nx_uint16_t counter;
} msg_ack_t;

#define REQ_MSG 1
#define RESP_MSG 2

enum{
AM_SEND_MSG = 6,
};

#endif
