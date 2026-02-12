import asyncio
from bleak import BleakScanner, BleakClient
import datetime

DEVICE_NAME = "BPBIO320_1640"
NUS_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
WRITE_UUID1  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
NOTIFY_UUID1 = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

#WRITE_UUID2  = "496e4254-0332-4246-889f-d178d72f3e05"
#NOTIFY_UUID2 = "496e4254-0333-4246-889f-d178d72f3e05"

# ================================
# notify 핸들러
# ================================
def noti_handler(sender, data):
    print("<<< notify:", " ".join(f"{b:02X}" for b in data))
def noti_handler_pressure(sender, data):
    print("<<< pressure:", " ".join(f"{b:02X}" for b in data))
def noti_handler_heartrate(sender, data):
    print("<<< hr:", " ".join(f"{b:02X}" for b in data))


# ================================
# 장치 검색
# ================================
async def find_device():
    print("🔍 scanning...")
    devices = await BleakScanner.discover(timeout=5)
    for d in devices:
        if d.name:
            print("✅ found:", d.address, d.name)
        if d.name == DEVICE_NAME:
            return d.address
    return None

    
async def load_services(client):
    print("📡 waiting for gatt services...")
    for _ in range(5):
        if client.services: 
            break
        await asyncio.sleep(0.1)

    if not client.services:
        raise RuntimeError("GATT services not loaded")

    for service in client.services:
        # description 속성 사용 가능
        name = service.description if hasattr(service, "description") else "Unknown"
        print(f"🔧 {service.uuid} | {name}")
        for char in service.characteristics:
            char_name = char.description if hasattr(char, "description") else "Unknown"
            print(f"   📎 {char.uuid} | {char_name} | {char.properties}")
    print("✅ services ready")
    
    
# ================================
# 명령 전송
# ================================
async def send_cmd(client, cmd):

    commands = {
    # 혈압 측정 시작 (RC)
    "measure_start": bytearray([
        0x16, 0x16, 0x01,0x30, 0x30, 0x02, 0x52, 0x43,   0x03, 0x11         
    ]),

    # 마지막 측정 결과 요청 (RB)
    "request_log": bytearray([
        0x16, 0x16,  # SYN SYN
        0x01,        # SOH
        0x30,        # STX
        0x30,        # Command group
        0x02, 0x52, 0x42,  # "RB"
        0x03,        # ETC
        0x10         # BCC
    ]),
}

    if cmd not in commands:
        print("❌ unknown cmd")
        return

    # response=True 로 안정성 확보
    await client.write_gatt_char(WRITE_UUID1, commands[cmd], response=True)
    print(">>> sent:", cmd)

# ================================
# 연결 및 notify 활성화
# ================================
async def connect_device(address):
    client = BleakClient(address, use_cached=False)
    await client.connect()
    await load_services(client)

    # Windows BLE 안정화
    await asyncio.sleep(0.3)

    # notify 먼저 설정
    await client.start_notify(NOTIFY_UUID1, noti_handler)
    await asyncio.sleep(0.2)
    #await client.start_notify(NOTIFY_UUID2, noti_handler2)
    #await asyncio.sleep(0.2)

    print("📡 connected & notify active")
    return client

# ================================
# 메인 루프
# ================================
async def main():
    address = None
    while not address:
        address = await find_device()
        await asyncio.sleep(1)

    while True:
        try:
            client = await connect_device(address)

            while True:
                cmd = await asyncio.to_thread(input, "cmd (status_time/log/exit): ")
                if cmd == "exit":
                    await client.disconnect()
                    return
                await send_cmd(client, cmd)

        except Exception as e:
            print("💥 disconnected, retrying...", e)
            await asyncio.sleep(2)

# ================================
asyncio.run(main())



"""

496e4254-0331-4246-889f-d178d72f3e05 : 개발용 서비스 (로우데이터?) 6e400001-b5a3-f393-e0a9-e50e24dcca9e : 진행상태 서비스
00001810 = Blood Pressure Service
0000180D = Heart Rate Service


 waiting for gatt services...
📡 waiting for gatt services...
🔧 00001801-0000-1000-8000-00805f9b34fb | Generic Attribute Profile
   📎 00002a05-0000-1000-8000-00805f9b34fb | Service Changed | ['indicate']
🔧 00001800-0000-1000-8000-00805f9b34fb | Generic Access Profile
   📎 00002a00-0000-1000-8000-00805f9b34fb | Device Name | ['read']
🔧 0000180a-0000-1000-8000-00805f9b34fb | Device Information
   📎 00002a29-0000-1000-8000-00805f9b34fb | Manufacturer Name String | ['read']
   📎 00002a24-0000-1000-8000-00805f9b34fb | Model Number String | ['read']
   📎 00002a28-0000-1000-8000-00805f9b34fb | Software Revision String | ['read']
🔧 6e400001-b5a3-f393-e0a9-e50e24dcca9e | Nordic UART Service
   📎 6e400003-b5a3-f393-e0a9-e50e24dcca9e | Nordic UART TX | ['notify']
   📎 6e400002-b5a3-f393-e0a9-e50e24dcca9e | Nordic UART RX | ['write-without-response', 'write']
🔧 496e4254-0331-4246-889f-d178d72f3e05 | Unknown
   📎 496e4254-0333-4246-889f-d178d72f3e05 | Unknown | ['notify']
   📎 496e4254-0332-4246-889f-d178d72f3e05 | Unknown | ['write-without-response', 'write']
🔧 496e4254-0340-4246-889f-d178d72f3e05 | Unknown
   📎 496e4254-0341-4246-889f-d178d72f3e05 | Unknown | ['notify', 'write-without-response', 'read', 'write']
🔧 00001810-0000-1000-8000-00805f9b34fb | Blood Pressure
   📎 00002a35-0000-1000-8000-00805f9b34fb | Blood Pressure Measurement | ['indicate']
   📎 00002a36-0000-1000-8000-00805f9b34fb | Intermediate Cuff Pressure | ['notify']
   📎 00002a49-0000-1000-8000-00805f9b34fb | Blood Pressure Feature | ['read']
🔧 0000180d-0000-1000-8000-00805f9b34fb | Heart Rate
   📎 00002a37-0000-1000-8000-00805f9b34fb | Heart Rate Measurement | ['notify']
   📎 00002a38-0000-1000-8000-00805f9b34fb | Body Sensor Location | ['read']
   📎 00002a39-0000-1000-8000-00805f9b34fb | Heart Rate Control Point | ['write']
🔧 0000181b-0000-1000-8000-00805f9b34fb | Body Composition
   📎 00002a9b-0000-1000-8000-00805f9b34fb | Body Composition Feature | ['read']
   📎 00002a9c-0000-1000-8000-00805f9b34fb | Body Composition Measurement | ['indicate']
🔧 1d14d6ee-fd63-4fa1-bfa4-8f47b42119f0 | Unknown
   📎 f7bf3564-fb6d-4e53-88a4-5e37e0326063 | Unknown | ['write']

   
   
   
   cmd (status_time/log/exit): 
<<< notify: 11 0B 0B 4B 22 13 20 00 2A C9
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 11 41
<<< notify: 11 41
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 91 01
<<< notify: 11 41
<<< notify: 11 41
<<< notify: 11 09
<<< notify: 11 09
<<< notify: 11 01
<<< notify: 11 41
<<< notify: 11 41
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 11 41
<<< notify: 69 59
<<< notify: 11 41
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 11 09
<<< notify: 11 09
<<< notify: 11 49
<<< notify: 11 49
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 03
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 4B
<<< notify: 11 43
<<< notify: 11 03
<<< notify: 11 0B
<<< notify: 11 01
<<< notify: 91 01
<<< notify: 11 41
<<< notify: 11 01
<<< notify: 11 41
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 11 09
<<< notify: 91 03
<<< notify: 11 03
<<< notify: 91 43
<<< notify: 11 03
<<< notify: 11 01
<<< notify: 11 01
<<< notify: 11 09
<<< notify: 11 01
<<< notify: 91 01
<<< notify: 11 41
<<< notify: 11 41
<<< notify: 11 49
<<< notify: 91 01
<<< notify: 11 41
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 43
<<< notify: 11 41
<<< notify: 69 59
<<< notify: 11 0B 0B 4B 22 03 66 04 46 D3



0A 13 B4 5D 20 E8 A4 BC 9D B0 D8 4F 05 85 E4 CF D1
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 1C DC FD 9F 5F 53 38 EA 88 D7 5A E6 29 05 FF EF
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 50 79 35 81 12 C5 4A D3 E7 2D 7C 0E 22 70 8A 4C
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 A5 DE 55 22 7E C4 AC AE F0 E5 D1 63 BA D5 AD ED
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 A5 DE 55 22 7E C4 AC AE F0 E5 D1 63 BA D5 AD ED
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 8C 1D 0A 80 7E CD 16 60 AC 74 21 12 ED 18 11 C8
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 1C 7B 8A 21 7F 61 D2 21 68 2E B9 D1 EC 24 5B C8
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 7E E6 9F C9 88 CA 96 C6 17 A1 F9 DB F3 8B 37 89
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 A5 DE 55 22 7E C4 AC AE F0 E5 D1 63 BA D5 AD ED
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 02 8A BD C9 35 29 8A C9 FD 0A 1C BA 22 FB 3C DC D8
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 EE 59 43 80 DD 96 F9 7A D6 F3 4B AF 21 04 B0 14
<<< notify2: 02 DE 76 52 BE A6 3E 1B 39 8B BB E4 3D 3C EC 71 73
<<< notify2: 02 49 20 06 09 E4 0A BE E8 50 2A 0F 2A 41 65 AF 68
<<< notify2: 02 A5 DE 55 22 7E C4 AC AE F0 E5 D1 63 BA D5 AD ED
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 EA EC C0 D5 06 81 EE 4F 67 3B D6 2D CE DA 50 B9
<<< notify2: 02 CA 77 47 97 85 4C 66 FA FA DC 22 74 F7 EA 68 16
<<< notify2: 0A CA A3 79 BF 82 50 0E 71 34 50 3E BB DD 84 05 E6




cmd (status_time/log/exit): request_log
>>> sent: request_log
cmd (status_time/log/exit): <<< notify: 16 16 01 30 30 02 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 30 1E 52 42 1E 30 30 30 30 30 1E 53 31 31 33 1E 4D 30 30 30 1E 44 30 37 36 1E 50 30 37 37 1E 4F 31 30 1E 30 30 30 30 1E 03 48


"""