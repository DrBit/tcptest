/*
Seed counter tests

*/


#include <SPI.h>
#include <Ethernet.h>


// Enter a MAC address and IP address for your controller below.
// The IP address will be dependent on your local network:
byte mac[] = {  0xDE, 0xAD, 0xBA, 0xEF, 0xFE, 0xED };
byte ip[] = { 10,250,1,199 };
byte server[] = { 10,250,1,3 }; // Google
int port = 8888;
boolean connection_alive = false;

#define bufferSize 21
char commandBuffer[bufferSize];

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
	Serial.println(ip_to_str(ip));
	
	Serial.print ("Default server ip: ");
	Serial.println(ip_to_str(server));
	
	Serial.print ("Default server port: ");
	Serial.println(port);
	
	Serial.print("\r\nChange server and port? [y/n]\r\n");
	
	if (YN_question ()) {
		receive_printer_IP ();
		receive_printer_PORT ();
	}
	

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
		// read them and buffer them, when return is pressed send them out the socket if it's open:
		while (Serial.available() > 0) {
		
			char inChar = Serial.read();
			if ((inChar == 13) || (inChar == 10)) {
				if (client.connected()) {
					print_to_server(commandBuffer);
					clean_buffer (commandBuffer,bufferSize);
				}else{
					Serial.println("Failed to send command, client not available.");
				}
			}else{
				buffer_char (inChar,commandBuffer,bufferSize);	
			}		
		}
	 
		// if the server's disconnected, stop the client:
		 if (!client.connected()) {
			Serial.println("Server Disconnected.");
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
		print_to_server ("Hello Server\r\nThis is an example of command:\r\nP*");
		// testing generated commands
		client.print("1P");
		client.print(1);
		client.print("\r\n");
		delay (300);
		return true;
	} else {
		// kf you didn't get a connection to the server:
		Serial.println("connection failed");
	}
	return false;

}

void print_to_server (char* text) {

	if (strlen(text) > 0) {		// If text empty wont print anything
		client.print(text);
		client.print("\r\n");
		Serial.print(text);
		Serial.print("\r\n");
	}
}

void buffer_char (char character, char* bufferContainer, int max_size) {
	int len = max_size;
	int actualLen = strlen(bufferContainer);
	char temp_char = character;
	
	if (actualLen < len-1) {
		bufferContainer[actualLen] = temp_char;
	}else{
		Serial.print("buffer full, max ");
		Serial.print(len-1,DEC);
		Serial.println(" characters per command.");
	}
}

void clean_buffer (char* bufferContainer, int max_size) {
	int len = max_size;
	for (int c = 0; c < len; c++) {
		bufferContainer[c] = 0;
	}
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
	Serial.print ("Type server ip: ");
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

void receive_printer_PORT () {
	Serial.print ("Type server port: ");
	Serial.flush ();
	const int buf_port = 6;
	char printerPort[buf_port];
	recevie_data (printerPort,buf_port);
	char * thisChar = printerPort;
	port = atoi(thisChar);
	Serial.println (port);
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
			if ((c == 13) || (c == 10)) { 	// begining or end of command
				//end
				if (strlen(parameter_container) > 0) {	// We have to receive something first
					parameter_container[strlen(parameter_container)] = '\0';
					return true;
				}
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

// Simple YES/NO Question
boolean YN_question () {
	while (true) {
		if (Serial.available ()) {
			char C = Serial.read ();
			if (C == 'y' || C == 'Y') {
				return true;
			}else if (C == 'n' || C == 'N') {
				return false;
			}
		}
	}
}
