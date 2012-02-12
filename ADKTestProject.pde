#include <Wire.h>
#include <Servo.h>
#include <Max3421e.h>
#include <Usb.h>
#include <AndroidAccessory.h>

#define uint8 unsigned char 
#define uint16 unsigned int
#define uint32 unsigned long int
 
// connect to digital 2,3
int Clkpin = 2;
int Datapin = 3;
int errFlag = 0;

// ADK Definition "sweemeng is the manufacture, 
// ADKTestProject is the device nme
AndroidAccessory acc("sweemeng",
                      "ADKTestProject",
                      "ADK Demo Code",
                      "0.1",
                      "http://www.android.com",
                      "0000000012345678");
// Begin LED Function
void ClkProduce(void)
{
  digitalWrite(Clkpin, LOW);
  delayMicroseconds(20); 
  digitalWrite(Clkpin, HIGH);
  delayMicroseconds(20);   
}
 
void Send32Zero(void)
{
    unsigned char i;
 
	for (i=0; i<32; i++)
	{
          digitalWrite(Datapin, LOW);
          ClkProduce();
    }
}
 
uint8 TakeAntiCode(uint8 dat)
{
    uint8 tmp = 0;
 
    if ((dat & 0x80) == 0)
    {
	    tmp |= 0x02; 
	}
 
	if ((dat & 0x40) == 0)
	{
	    tmp |= 0x01; 
	}
 
	return tmp;
}
 
// gray data
void DatSend(uint32 dx)
{
    uint8 i;
 
	for (i=0; i<32; i++)
	{
	    if ((dx & 0x80000000) != 0)
		{
	           digitalWrite(Datapin, HIGH);
		}
		else
		{
                    digitalWrite(Datapin, LOW);
		}
 
		dx <<= 1;
        ClkProduce();
	}
}
 
// data processing
void DataDealWithAndSend(uint8 r, uint8 g, uint8 b)
{
    uint32 dx = 0;
 
    dx |= (uint32)0x03 << 30;             // highest two bits 1，flag bits
    dx |= (uint32)TakeAntiCode(b) << 28;
    dx |= (uint32)TakeAntiCode(g) << 26;	
    dx |= (uint32)TakeAntiCode(r) << 24;
 
    dx |= (uint32)b << 16;
    dx |= (uint32)g << 8;
    dx |= r;
 
    DatSend(dx);
}
// End LED Function

void setup()  {
  // Serial is good, it is the print of Arduino
  Serial.begin(9600);
  Serial.println("\r\nADK Started\r\n");
  
  pinMode(Datapin, OUTPUT);
  pinMode(Clkpin, OUTPUT);

  // Start ADK
  acc.powerOn();
} 
 
void loop()  { 
  // Data Definition
  byte data[3];
  // Are we connected? 
  if(acc.isConnected()){
    // Yes we are, now lets read from Android App
    int len = acc.read(data,sizeof(data),1);
    int i;
    byte b;
    if(len > 0){
      blinks_it(data[0],data[1],data[2]);
      Serial.println("Command Received");
    }
    errFlag = 0;
  }
  else{
      blinks_it(0,0,0);
      if(errFlag == 0){
        Serial.println("Android not connected");
        errFlag = 1;
      }
  } 
}

void blinks_it(int r,int g, int b){
  Send32Zero(); // begin
  DataDealWithAndSend(r, g, b); // first node data
  Send32Zero();  // send to update data    
  delay(500);
}
