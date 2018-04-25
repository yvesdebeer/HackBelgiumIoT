 -- I've added code to send command (2 ways communication) but currently still being comment out. Pls read comment in line 61 below. 
-- If you want to be able to send command then uncomment those lines. However you will no longer be able use 'quickstart' as org ID. You must use registered org ID with its auth password.
--
orgID = "r1et2w" -- IoT Foundation organization ID <========== Modify this!
broker = orgID..".messaging.internetofthings.ibmcloud.com" -- IP or hostname of IoTF service
mqttPort = 1883 -- MQTT port (default 1883: non-secure)
userID = "use-token-auth" -- blank for quickstart
userPWD = "passw0rd" -- blank for quickstart <========== Modify this!
--macID = "18fe349e543f" -- unique Device ID or Ethernet Mac Address <=== Modify this!
macID = "MyESP8266"
clientID = "d:"..orgID..":ESP8266:"..macID -- Client ID
count = 0 -- Test number of mqtt_do cycles
mqttState = 0 -- State control

topicpb = "iot-2/evt/status/fmt/json"
topicmd = "iot-2/cmd/+/fmt/json" -- Topic for subscribing commands

pin = 4 -- GPIO2

-- Wifi credentials
SSID = "UMONS-EVENT"  -- <========== Modify this!
wifiPWD = "welcome-to-umons" -- <========== Modify this!

function wifi_connect()
 wifi.setmode(wifi.STATION)
 wifi.sta.config(SSID,wifiPWD)
 wifi.sta.connect()
 print("MAC address is " .. macID);
end


function mqtt_do()
 count = count + 1 -- tmr.alarm counter

 if mqttState < 5 then
 mqttState = wifi.sta.status() --State: Waiting for wifi
 wifi_connect()

 elseif mqttState == 5 then
 print("Starting to connect...")
 m = mqtt.Client(clientID, 120, userID, userPWD)

 m:on("offline", function(conn) 
 print ("Checking IoTF server...") 
 mqttState = 0 -- Starting all over again 
 end)
 
 m:on("message", 
 function(conn, topic, data)
 print(topic .. ":" ) -- receive the commands
 if data ~= nil then
 print(data)
 end
 end)

 m:connect(broker , mqttPort, 0, 
 function(conn)
 print("Connected to " .. broker .. ":" .. mqttPort)
 mqttState = 20 -- Go to publish state 

 -- To be able to send command, uncomment the next 4 lines of code.
 --m:subscribe(topicmd,0,
 --function(conn)
 --print("Successfully subscribe to commands...")
 --end) 
 -- 
 end)

 elseif mqttState == 20 then
 mqttState = 25 -- Publishing...
 status,temp,humi,temp_decimal,humi_decimal = dht.read11(pin) --read temperatur & humdity
 if( status == dht.OK ) then
 m:publish(topicpb ,'{"d": {"Temperature":'..temp..',"Humidity":'..humi..'}}', 0, 0,
 function(conn)
 -- Print confirmation of data published
 print("Sent message #"..count.." DHT Temperature:"..temp.."; ".."Humidity:"..humi)
 mqttState = 20 -- Finished publishing - go back to publish state.
 end)
 elseif( status == dht.ERROR_CHECKSUM ) then
 print( "DHT Checksum error." );
 elseif( status == dht.ERROR_TIMEOUT ) then
 print( "DHT Time out." );
 end

 else print("Waiting..."..mqttState)
 mqttState = mqttState - 1 -- takes us gradually back to publish state to retry
 end

end

tmr.alarm(2, 10000, 1, function() mqtt_do() end) -- send data every 10s
