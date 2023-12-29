#include <WiFi.h>
#include <PubSubClient.h>   //https://github.com/knolleary/pubsubclient

// WiFi Credentials
const char *ssid = "Redmi 9C";            // Enter your WiFi name
const char *password = "kazim@68";    // Enter WiFi password

// MQTT Broker
const char *mqtt_broker = "test.mosquitto.org";
const char *topic = "2022-CS-115/test";
const int mqtt_port = 1883;

const char *led1 = "led1";


bool led1Status = false;

WiFiClient espClient;
PubSubClient client(espClient);

void subscribeTopics(){
  client.subscribe(led1);
}

void setup()
{
  // Set software serial baud to 9600;
  Serial.begin(9600);

  // Use ESP32 buit-in LED to indicate the state of WiFi and MQTT
  //pinMode(LED_BUILTIN,OUTPUT);
  //digitalWrite(LED_BUILTIN, LOW);

  // connecting to a WiFi network
  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED)
  {
    //digitalWrite(LED_BUILTIN, HIGH); // LED ON while No WiFi
    delay(500);
    //Serial.println("Connecting to WiFi..");
  }
  //Serial.println("Connected to the WiFi network");
  //digitalWrite(LED_BUILTIN, LOW); // LED OFF when connected to WiFi
  //connecting to a mqtt broker
  client.setServer(mqtt_broker, mqtt_port);
  client.setCallback(callback);

  while (!client.connected())
  {
    //digitalWrite(LED_BUILTIN, HIGH); // LED ON while No MQTT Connection
    String client_id = "c6e48911-9509-4478-95c3-e3d04ee7ebcb";
    //Serial.printf("The client %s connects to the public mqtt broker\n", client_id.c_str());
    if (client.connect(client_id.c_str()))
    {
        Serial.println("MQTT Broker Connected Successfully");
        //digitalWrite(LED_BUILTIN, LOW); // LED OFF when connected to MQTT Server
    }
    else
    {
        Serial.print("MQTT connection failed with state ");
        //Serial.print(client.state());
        delay(2000);
    }
  }
  // publish and subscribe
  client.publish(topic, "I'm Master.inc");   // Testing MQTT publish
  subscribeTopics();            // Subscribing to a MQTT topic
}

void modifyL(char *info){
  if (String(info) == "led1"){
    if (led1Status){ 
      
  client.publish("red", "kuta");
  Serial.write("1");}
    else Serial.write("4");
  }
}

void callback(char *topic, byte *payload, unsigned int length)
{
 //Serial.print("Message arrived in topic: ");
 //Serial.println(topic);
 //Serial.print("Message:");
 for (int i = 0; i < length; i++)
 {
 
     //Serial.print((char) payload[i]);
 }
 //Serial.write(payload, length);
 //Serial.println();
 //Serial.println("-----------------------");
if (String(topic) == "led1"){
  client.publish("red", "on");
  led1Status = !led1Status;
  modifyL("led1");
}
 
}

void loop()
{

 client.loop();
  
}