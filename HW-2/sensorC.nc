#include "DATA/SENSOR_DATA.h"

generic module sensorC() {

	provides interface Read<uint16_t> as sensorRead;

	uses interface Timer<TMilli> as timerRead;


}

implementation {

	uint16_t data_index = 0;
	uint16_t read_value = 0;


	command error_t sensorRead.read(){

		read_value = SEN_DATA[data_index];
		data_index++;
		if(data_index==SEN_DATA_SIZE)
			data_index = 0;

		call timerRead.startOneShot( 1 );
		return SUCCESS;
	}
	//***************** Timer interfaces ********************//
	event void timerRead.fired() {
		signal sensorRead.readDone( SUCCESS, read_value );
	}

}
