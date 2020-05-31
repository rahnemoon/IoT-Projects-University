#include "Timer.h"
#include "printf.h"
#include "packetStructure.h"

module fieldNodeC @safe(){

  uses {
	interface Boot;
	interface SplitControl;
	interface Packet;
    interface AMSend;
    interface Receive;
    interface PacketAcknowledgements;
    interface Random;

    interface Timer<TMilli> as sendTimer;
  }

} implementation {

  message_t packet;
  bool busy = FALSE;


  void sendData();


  //***************** Send Data function ********************//
  void sendData() {
  	if (busy)
  	{
  		return;
  	}else{
	  	msg_struct_t* mess = (msg_struct_t*)(call Packet.getPayload(&packet, sizeof(msg_struct_t)));
		  if (mess == NULL) {
			return;
		  }
		  call PacketAcknowledgements.requestAck(&packet);
		  mess->value = (call Random.rand16()) % 101;
		  mess->topic = TOS_NODE_ID;
		  if(call AMSend.send(1, &packet,sizeof(msg_struct_t)) == SUCCESS){
#if LOG == 1
		    printf("    %u    %u\n", mess->topic, mess->value);
			printfflush();
#endif
			busy = TRUE;
	  	}
	  }
 }


  //***************** Boot interface ********************//
  event void Boot.booted() {
    call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t error){
    if(error == SUCCESS) {
		if (TOS_NODE_ID != 1){
	    	call sendTimer.startPeriodic( 5000 );
	    	printf("Node %u starts to send data\n", TOS_NODE_ID);
        	printfflush();
	  	}else{
	  		printf("Node %u starts to receive data\n", TOS_NODE_ID);
        	printfflush();
	  	}
    }else{
		printf("Radio is still off!\n");
		printfflush();
		call SplitControl.start();
    }
  }

  event void SplitControl.stopDone(error_t error){}

  //***************** MilliTimer interface ********************//
  event void sendTimer.fired() {
#if LOG == 1
  	printf("Send timer fired\n");
	printfflush();
#endif
  	sendData();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t error) {
	if (&packet == buf && error == SUCCESS) {
#if LOG == 1
		msg_struct_t* mess = (msg_struct_t*)(call Packet.getPayload(&packet, sizeof(msg_struct_t)));
		printf("    %u    %u\n", mess->topic, mess->value);
      	printfflush();
#endif
    	busy = FALSE;
    }else{
      printf("Send done error!");
      printfflush();
    }
  }


  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* bufPtr,void* payload, uint8_t len) {
	if (len != sizeof(msg_struct_t)) {return bufPtr;}
    else {
    	msg_struct_t* mess = (msg_struct_t*)payload;
		printf("    %u    %u\n", mess->topic, mess->value);
      	printfflush();
	    return bufPtr;
    }
    {
      printf("Receiving error \n");
      printfflush();
    }
  }

}
