#include <Timer.h>
#include "RadioCountIdLeds.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration RadioCountIdLedsAppC {
}
implementation {
  components MainC;
  components LedsC;
  components RadioCountIdLedsC as App;
  components new TimerMilliC() as MilliTimer;
  components new TimerMilliC() as Mode10_MilliTimer;
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components PrintfC;
  components SerialStartC;


  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.MilliTimer -> MilliTimer;
  App.Mode10_MilliTimer -> Mode10_MilliTimer;
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
}
