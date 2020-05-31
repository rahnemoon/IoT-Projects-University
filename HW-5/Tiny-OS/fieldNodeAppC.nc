#include <Timer.h>
#include "packetStructure.h"
#define NEW_PRINTF_SEMANTICS
#include "printf.h"

configuration fieldNodeAppC {}

implementation {

  components MainC, fieldNodeC as App;
  components new TimerMilliC() as sendTimer;
  components ActiveMessageC;
  components new AMSenderC(AM_SEND_MSG);
  components new AMReceiverC(AM_SEND_MSG);
  components RandomC;
  components PrintfC;
  components SerialStartC;

  App.Boot -> MainC.Boot;
  App.sendTimer -> sendTimer;
  App.SplitControl -> ActiveMessageC;
  App.Random -> RandomC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.PacketAcknowledgements ->AMSenderC.Acks;
}

