/*
Web client

This sketch connects to a website (http://www.google.com)
using an Arduino Wiznet Ethernet shield. 

Circuit:
* Ethernet shield attached to pins 10, 11, 12, 13

created 18 Dec 2009
by David A. Mellis

*/


#include <SPI.h>
#include <Ethernet.h>


// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {  0xDE, 0xAD, 0xBA, 0xEF, 0xFE, 0xED };
byte ip[] = { 10,250,1,199 };
byte server[] = { 10,42,43,51 }; // Google
int port = 8080;


boolean connection_alive = false;


// Initialize the Ethernet client library
// with the IP address and port of the server 
// that you want to connect to (port 80 is default for HTTP):
EthernetClient client;


void setup() {
	// start the Ethernet connection:
	Ethernet.begin(mac, ip);
	// start the serial library:
	Serial.begin(9600);
	// give the Ethernet shield a second to initialize:
	delay(1000);

	Serial.print("Starting on IP: ");
	Serial.print(ip_to_str(ip));
	Serial.println("");

	Serial.print ("Type server ip: ");

	receive_printer_IP ();

	connection_alive = connect_to_client ();
  
}


void loop()
{
	if (connection_alive) {
		// if there are incoming bytes available 
		// from the server, read them and print them:
		if (client.available()) {
			char c = client.read();
			Serial.print(c);
		}
	 
		// as long as there are bytes in the serial queue,
		// read them and send them out the socket if it's open:
		while (Serial.available() > 0) {
			char inChar = Serial.read();
			if (client.connected()) {
				client.print(inChar); 
				Serial.print(inChar);
			}
		}
	 
		// if the server's disconnected, stop the client:
		 if (!client.connected()) {
			Serial.println("Server Disconnected.");
			Serial.println();
			client.stop();
			connection_alive = false;
		}
	 
	}else{
		connection_alive = connect_to_client ();
		// wait 20 seconds before connecting again.
		delay (5000);   //5 seconds for testing
	}
  
}




boolean connect_to_client () {
	Serial.print("\nconnecting to: ");
	Serial.print(ip_to_str(server));
	Serial.print(":"); Serial.println (port);

	// if you get a connection, report back via serial:
	if (client.connect(server, port)) {
		Serial.println("connected!");
		return true;
	} else {
		// kf you didn't get a connection to the server:
		Serial.println("connection failed");
	}
	return false;

}


 
 
 
 // Just a utility function to nicely format an IP address.
const char* ip_to_str(const uint8_t* ipAddr)
{
	static char buf[16];
	sprintf(buf, "%d.%d.%d.%d\0", ipAddr[0], ipAddr[1], ipAddr[2], ipAddr[3]);
	return buf;
}




/***** Checks free ram and prints it serial *****/
void mem_check () {
	//checking memory:
	Serial.print("Memory available: [");
	Serial.print(freeRam());
	Serial.println(" bytes]");
}


/***** Returns free ram *****/
int freeRam () {
	extern int __heap_start, *__brkval; 
	int v; 
	return (int) &v - (__brkval == 0 ? (int) &__heap_start : (int) __brkval); 
}


void receive_printer_IP () {
	Serial.flush ();
	int buf_ip =17; // 17 is the maximum numbers an IP can contain (including dots) 
	char printerIP[buf_ip]; 
	recevie_data (printerIP,buf_ip);
	// Serial.println (printerIP);
	// Staring of script
	String SprinterIP = printerIP;
	// convert into -> byte printer_ipAddr[4]
	// ip 10.11.12.13
	int firstDot = SprinterIP.indexOf('.');
	int secondDot = SprinterIP.indexOf('.', firstDot + 1 );
	int thirdDot = SprinterIP.indexOf('.', secondDot + 1 );
	int lastChar = SprinterIP.length();


	int num = 0; 
	// when you cast the individual chars to ints you will get their ascii table equivalents 
	// Since the ascii values of the digits 1-9 are off by 48 (0 is 48, 9 is 57), 
	// you can correct by subtracting 48 when you cast your chars to ints.
	for (int i = (firstDot-1); i>=0 ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	server[0] = (byte) num;
	num = 0;
	for (int i = (secondDot-1); i>=(firstDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	server[1] = (byte) num;
	num = 0;
	for (int i = (thirdDot-1); i>=(secondDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	server[2] = (byte) num;
	num = 0;
	for (int i = (lastChar-1); i>=(thirdDot+1) ; i--) {
		num = atoi(&printerIP[i]);
	}
	//Serial.println (num);
	server[3] = (byte) num;


	Serial.println (ip_to_str(server));


}


boolean recevie_data (char* parameter_container,int buffer) {
	// first clean data
	int len = buffer;
	for (int c = 0; c < len; c++) {
		parameter_container[c] = 0;
	}


	while (true) {
		while (Serial.available()) {
			char c = (char) Serial.read();
			//Serial.print (Serial.read()); // JUST for debug
			if (c == 13) { // begining or end of command
				//end
				parameter_container[strlen(parameter_container)] = '\0';
				return true;
			}else{
					if (strlen(parameter_container) == buffer ) {
					// Serial.println (" Reached the data max lengh, we reset the tag" );
					// Error!! buffer overload
					return false;
				}else{
					// DATA comes here
					// Serial.print (c);
					parameter_container[strlen(parameter_container)]=c;
					// DEBUG IP
				}
			}
		}
	}
}
