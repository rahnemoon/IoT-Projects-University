// $Id: RadioCountIdLedsC.nc,v 1.7 2010-06-29 22:07:17 scipio Exp $

#include "Timer.h"
#include "printf.h"

#include "RadioCountIdLeds.h"
 
/**
 * Implementation of the RadioCountToLeds application. RadioCountToLeds 
 * maintains a 4Hz counter, broadcasting its value in an AM packet 
 * every time it gets updated. A RadioCountToLeds node that hears a counter 
 * displays the bottom three bits on its LEDs. This application is a useful 
 * test to show that basic AM communication and timers work.
 *
 * @author Philip Levis
 * @date   June 6 2005
 */

module RadioCountIdLedsC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface Timer<TMilli> as Mode10_MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
    interface AMPacket;
  }
}
implementation {

  message_t packet;
  bool busy = FALSE;
  bool offMode10 = FALSE;
  uint16_t counter = 0;

  void setLedsToggle(uint8_t val) {
    if (val == 1 && !offMode10)
#if LOG == 1
      printf("Node %u: Toggle LED 0 \n", TOS_NODE_ID);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: Toggle LED 0 on node %hu\n", TOS_NODE_ID);
#endif
      call Leds.led0Toggle();
    if (val == 2 && !offMode10){
#if LOG == 1
      printf("Node %u: Toggle LED 1 \n", TOS_NODE_ID);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: Toggle LED 1 on node %hu\n", TOS_NODE_ID);
#endif
      call Leds.led1Toggle();
    }
    if (val == 3 && !offMode10){
#if LOG == 1
      printf("Node %u: Toggle LED 2 \n", TOS_NODE_ID);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: Toggle LED 2 on node %hu\n", TOS_NODE_ID);
#endif
      call Leds.led2Toggle();
    }
  }

  void setLedsOff() { 
    call Leds.led0Off();
    call Leds.led1Off();
    call Leds.led2Off();
    offMode10 = TRUE;
  }
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      if(TOS_NODE_ID == 1) {
        call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI_1);
#if LOG == 1
        printf("Node %u: timer started with duration=%u \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_1);
        printfflush();
#elif LOG == 2
        dbg("RadioCountIdLedsC", "RadioCountIdLedsC: timer started in node %hu with duration=%hhu. \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_1);
#endif
      }
      else if (TOS_NODE_ID == 2) {
        call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI_2);
#if LOG == 1
        printf("Node %u: timer started with duration=%u \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_2);
        printfflush();
#elif LOG == 2
        dbg("RadioCountIdLedsC", "RadioCountIdLedsC: timer started in node %hu with duration=%hhu. \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_2);
#endif
      }
      else if (TOS_NODE_ID == 3) {
        call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI_3);
#if LOG == 1
        printf("Node %u: timer started with duration=%u \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_3);
        printfflush();
#elif LOG == 2
        dbg("RadioCountIdLedsC", "RadioCountIdLedsC: timer started in node %hu with duration=%hhu. \n", TOS_NODE_ID, TIMER_PERIOD_MILLI_3);
#endif
      }
      else{ 
        return;
      }
      call Mode10_MilliTimer.startPeriodic(TIMER_PERIOD_MILLI_MODE_10);
#if LOG == 1
      printf("Node %u: Successful start \n", TOS_NODE_ID);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: Successful start in node %hu\n", TOS_NODE_ID);
#endif
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
#if LOG == 1
    printf("Node %u: timer fired, counter is %u.\n", counter);
    printfflush();
#elif LOG == 2
    dbg("RadioCountIdLedsC", "RadioCountIdLedsC: timer fired, counter is %hu.\n", counter);
#endif
    if (busy) {
      return;
    }
    else {
      RadioCountIdMsg_t* rcipkt = (RadioCountIdMsg_t*)call Packet.getPayload(&packet, sizeof(RadioCountIdMsg_t));
      if (rcipkt == NULL) {
         return;
      }
      rcipkt->counter = counter;
      rcipkt->nodeId = TOS_NODE_ID;
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(RadioCountIdMsg_t)) == SUCCESS) {
#if LOG == 1
        printf("Node %u: packet sned %u with counter = \n", TOS_NODE_ID, rcipkt->counter);
        printfflush();
#elif LOG == 2
        dbg("RadioCountIdLedsC", "RadioCountIdLedsC: packet sent.\n"); 
#endif
      busy = TRUE;
      }
    }
  }

  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (!offMode10){
      counter++;
    }
#if LOG == 1
    printf("Node %u: counter %u\n", TOS_NODE_ID, counter);
    printfflush();
#elif LOG == 2
    dbg("RadioCountIdLedsC", "RadioCountIdLedsC: Received packet of length %hhu.\n", len);
#endif
    if (len != sizeof(RadioCountIdMsg_t)) {return bufPtr;}
    else {
      RadioCountIdMsg_t* rcipkt = (RadioCountIdMsg_t*)payload;
#if LOG == 1
      printf("Node %u: packet from %u with counter = %u \n", TOS_NODE_ID, rcipkt->nodeId, rcipkt->counter);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: packet from %hu with counter = %hhu.\n", rcipkt->nodeId, rcipkt->counter);
#endif
      setLedsToggle(rcipkt->nodeId);
      if (rcipkt->counter % 10 == 0)
      {   
#if LOG == 1
          printf("Node %u: LEDs off for 5 sec\n", TOS_NODE_ID);
          printfflush();
#elif LOG == 2
          dbg("RadioCountIdLedsC", "RadioCountIdLedsC: LEDs off for 5 sec in node %hu\n", TOS_NODE_ID);
#endif
          setLedsOff();
      }
      return bufPtr;
    }
  }

  event void Mode10_MilliTimer.fired() {
    // dbg("RadioCountIdLedsC", "RadioCountIdLedsC: timer fired, counter is %hu.\n", counter);
    if (offMode10) {
      offMode10 = FALSE;
    }
#if LOG == 1
      printf("Node %u: LEDs on\n", TOS_NODE_ID);
      printfflush();
#elif LOG == 2
      dbg("RadioCountIdLedsC", "RadioCountIdLedsC: LEDs on in node %hu\n", TOS_NODE_ID);
#endif
  }

  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
        busy = FALSE;
    }
  }
}
