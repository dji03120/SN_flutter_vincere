import asyncio
from bleak import BleakScanner, BleakClient
import traceback

if 1 :
    SERVICE_UUID = "0000ffb0-0000-1000-8000-00805f9b34fb"
    WRITE_UUID = "0000fee2-0000-1000-8000-00805f9b34fb"
    NOTIFY_UUID = "0000fee1-0000-1000-8000-00805f9b34fb"
    DEVICE_NAME = "F_Scale_A"

message_dict = {
    "get_version":           "A5 56 00",
    "sync_time":             "A5 55 00",
    "sync_user":             "A5 53 01 01 32 64 00",  
    "sync_unit_kg":          "A5 52 00",
    "sync_history":          "A5 51 00",
    "get_decimal_info":      "A5 57 00",
}
global_client = None
            
            
            
def notification_handler(sender, data):
    try:
        print(">>> [recv]", end=' ')
        for b in data: print(f"{b:02X}", end=' ')
        print()
        #asyncio.create_task(send_message(global_client, message_dict['ack'], with_checksum=False))
    except:
        print(traceback.format_exc())


async def scan_device(device_name):
    print("BLE 장치 스캔 중...")
    devices = await BleakScanner.discover()
    for device in devices:
        if device.name:
            print(f"Found: {device.name} - {device.address}")
            if device.name == device_name:
                return device
    return None


async def get_services(client):
    client
    services = client.services
    for service in services:
        print(f"🔧 Service: {service.uuid}")
        for char in service.characteristics:
            print(f"   📎 Characteristic: {char.uuid}")
            print(f"      🔸 Properties: {char.properties}")
            print()




async def send_message(client, hex_code, with_checksum=True):
    hex_code = bytearray.fromhex(hex_code)
    if with_checksum:
        checksum = 0
        for b in hex_code: 
            checksum ^= b
        hex_code.append(checksum)
        
    print("<<< [send]", end=' ')
    for b in hex_code: print(f"{b:02X}", end=' ')
    print()
    await client.write_gatt_char(WRITE_UUID, hex_code, response=False) # without response 
    #await client.write_gatt_char(NOTIFY_UUID, hex_code) #
    await asyncio.sleep(0.1)




async def keep_alive(client, message, interval=0.5):
    while client.is_connected:
        try: 
            await send_message(client, message)
            #await client.write_gatt_char(WRITE_UUID, bytes(b'hello world'), response=False)
        except Exception as e:
            print("⚠️ keep-alive 실패:", e)
            break
        await asyncio.sleep(interval)




async def user_input_loop(client, message_dict):
    while True:
        cmd = await asyncio.to_thread(input, "보낼 명령 입력 (예: info, battery, stop, exit) : ")
        if cmd == "exit": break
        if cmd in message_dict: await send_message(client, message_dict[cmd])
        else: print("❌ 지원하지 않는 명령")




async def run():
    global global_client
    try:
        print(f"🔗 {DEVICE_NAME} 장치 실행 필요")
        device = None
        while not device:
            device = await scan_device(DEVICE_NAME)
            await asyncio.sleep(0.3)

        while True:
            print(f"🔗 {DEVICE_NAME}({device.address})에 연결 시도 중...")
            async with BleakClient(device.address) as client:
                await get_services(client)
                if not client.is_connected:
                        print("연결 실패")
                        return
                global_client = client
                await client.start_notify(NOTIFY_UUID, notification_handler)
                await asyncio.gather(
                    #keep_alive(client, message_dict[''], interval=0.5 ),
                    user_input_loop(client, message_dict),
                )


    except Exception:
        print(traceback.format_exc())

asyncio.run(run())



