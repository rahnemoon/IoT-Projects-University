#include "sensorSendAck.h"

configuration sensorSendAckAppC {}

implementation {

  components MainC, sensorSendAckC as App;
  components new TimerMilliC() as requestTimer;
  components new sensorAppC() as sensorApp;
  components ActiveMessageC;
  components new AMSenderC(AM_SEND_MSG);
  components new AMReceiverC(AM_SEND_MSG);
  App.Boot -> MainC.Boot;
  App.requestTimer -> requestTimer;
  App.sensorRead -> sensorApp.sensorRead;
  App.SplitControl -> ActiveMessageC;
  App.AMSend -> AMSenderC;
  App.Packet -> AMSenderC;
  App.Receive -> AMReceiverC;
  App.PacketAcknowledgements ->AMSenderC.Acks;
}

