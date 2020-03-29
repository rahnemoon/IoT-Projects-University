#include "Timer.h"
#include "sensorSendAck.h"

module sensorSendAckC @safe(){

  uses {
	interface Boot;
	interface SplitControl;
	interface Packet;
    interface AMSend;
    interface Receive;
    interface PacketAcknowledgements;

    interface Timer<TMilli> as requestTimer;

	interface Read<uint16_t> as sensorRead;

  }

} implementation {

  uint16_t counter=0;
  uint8_t rec_id;
  message_t packet;
  bool busy = FALSE;


  void sendReq();
  void sendResp();


  //***************** Send request function ********************//
  void sendReq() {
  	if (busy)
  	{
  		return;
  	}else{
	  	msg_ack_t* mess = (msg_ack_t*)(call Packet.getPayload(&packet, sizeof(msg_ack_t)));
		  if (mess == NULL) {
			return;
		  }
		  call PacketAcknowledgements.requestAck(&packet);
		  counter++;
		  mess->type = REQ_MSG;
		  mess->value = 0;
		  mess->counter = counter;

		  dbg("radio_pack","Preparing the  request message... \n");

		  if(call AMSend.send(1, &packet,sizeof(msg_ack_t)) == SUCCESS){
		    dbg("radio_send", "Request packet passed to lower layer successfully!\n");
		    dbg("radio_pack",">>>Request packet\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
		    dbg_clear("radio_pack","\t Payload Sent\n" );
			dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
			dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->value);
			dbg_clear("radio_pack", "\t\t counter: %hhu \n", mess->counter);
			busy = TRUE;
	  	}
	  }
 }

  //****************** Task send response *****************//
  void sendResp() {

  	if (busy)
  	{
  		return;
  	}else{
		call sensorRead.read();
	}
  }

   void sendData(uint16_t data, uint8_t type){
	  msg_ack_t* mess = (msg_ack_t*)(call Packet.getPayload(&packet, sizeof(msg_ack_t)));
	  if (mess == NULL) {
		return;
	  }
	  mess->type = type;
	  mess->value = data;
	  call PacketAcknowledgements.requestAck(&packet);
	  dbg("radio_pack","Preparing the  response message... \n");

	  if(call AMSend.send(0, &packet,sizeof(msg_ack_t)) == SUCCESS){
	     dbg("radio_send", "Response packet passed to lower layer successfully!\n");
	     dbg("radio_pack",">>>Response packet\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	     dbg_clear("radio_pack","\t Payload Sent\n" );
		 dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
		 dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->value);

  	}
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted on node %u.\n", TOS_NODE_ID);
    call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t error){
    if(error == SUCCESS) {
    	dbg("radio", "Radio on!\n");
	if (TOS_NODE_ID == 0){
           call requestTimer.startPeriodic( 1000 );
  	}
    }else{
		dbgerror("radio", "Radio is still off!\n");
		call SplitControl.start();
    }
  }

  event void SplitControl.stopDone(error_t error){}

  //***************** MilliTimer interface ********************//
  event void requestTimer.fired() {
  	dbg("timer","Request timer fired at %s.\n", sim_time_string());
  	sendReq();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t error) {
	if (&packet == buf && error == SUCCESS) {
		msg_ack_t* payload = (msg_ack_t*)(call Packet.getPayload(&packet, sizeof(msg_ack_t)));
		if (TOS_NODE_ID == 0 )
		{
			dbg("radio_send", "Request packet sent...");
      		dbg_clear("radio_send", " at time %s \n", sim_time_string());
			if(call PacketAcknowledgements.wasAcked(buf)){
		   		dbg_clear("ack", "Request # %hhu at time %s acknowledged \n", payload->counter, sim_time_string());
		      	if (call requestTimer.getdt() > 1000)
		      	{
		      		call requestTimer.startPeriodic( call requestTimer.getdt() / 2);
		      	}
		    }else{
		  		dbg("ack", "Request # %hhu at time %s  not acknowledged \n", payload->counter, sim_time_string());
	      		sendReq();
	      		if (call requestTimer.getdt() < 20000)
		  		{
		    		call requestTimer.startPeriodic(call requestTimer.getdt() * 2);
		      	}
		    }
		}else{
			dbg("radio_send", "Response packet sent...");
	        dbg_clear("radio_send", " at time %s \n", sim_time_string());
	        if(call PacketAcknowledgements.wasAcked(buf)){
	      		dbg("ack", "Response # %hhu with %hhu at time %s acknowledged\n", payload->counter, payload->value, sim_time_string());
	      	}else{
	      		dbg("ack", "Response # %hhu with %hhu at time %s not acknowledged\n", payload->counter, payload->value, sim_time_string());
	      		sendResp();
	        }
		}
    	busy = FALSE;
    }else{
      dbgerror("radio_send", "Send done error!");
    }
  }


  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* bufPtr,void* payload, uint8_t len) {
	if (len != sizeof(msg_ack_t)) {return bufPtr;}
    else {
    	msg_ack_t* mess = (msg_ack_t*)payload;
    	if (TOS_NODE_ID == 0)
    	{
		    dbg("radio_rec", "Received  response packet at time %s\n", sim_time_string());
		    dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
		    dbg("radio_pack", ">>>Pack \n");
		    dbg_clear("radio_pack","\t\t Payload Received\n" );
		    dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
			dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->value);

	      	return bufPtr;
    	}else{
    		sendResp();
    		dbg("radio_rec", "Received  request packet at time %s\n", sim_time_string());
		    dbg("radio_pack"," Payload length %hhu \n", call Packet.payloadLength( bufPtr ));
		    dbg("radio_pack", ">>>Pack \n");
		    dbg_clear("radio_pack","\t\t Payload Received\n" );
		    dbg_clear("radio_pack", "\t\t type: %hhu \n ", mess->type);
			dbg_clear("radio_pack", "\t\t data: %hhu \n", mess->value);

    		return bufPtr;
    	}
    }
    {
      dbgerror("radio_rec", "Receiving error \n");
    }
  }

  //************************* Read interface **********************//
  event void sensorRead.readDone(error_t result, uint16_t data) {
	double value = ((double)data/65535)*100;
	dbg("sensor","Sensor read done %f\n",value);
	sendData((uint16_t) value, RESP_MSG);
  }

}
