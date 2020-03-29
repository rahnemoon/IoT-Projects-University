
generic configuration sensorAppC() {

	provides interface Read<uint16_t> as sensorRead;

} implementation {

	components MainC;
	components new sensorC();
	components new TimerMilliC() as readTimer;
	sensorRead = sensorC.sensorRead;
	sensorC.timerRead -> readTimer;


}
