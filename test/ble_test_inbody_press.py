import asyncio
from bleak import BleakScanner, BleakClient
import traceback

DEVICE_NAME = "InBodyHGS-T425004652"

NUS_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
WRITE_UUID  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"   # RX
NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"   # TX


# ================================
# 장치 검색
# ================================
async def find_device():
    print("🔍 scanning...")
    devices = await BleakScanner.discover(timeout=5)
    for d in devices:
        if d.name != None:
            print("✅ found:", d.address, d.name)
            
        if d.name == DEVICE_NAME:
            print("✅ found:", d.address)
            return d.address
    return None


# ================================
# UART 깨우기 (필수)
# ================================
async def wake_uart(client):
    print("⚡ opening uart channel...")
    await client.write_gatt_char(
        WRITE_UUID,
        bytearray([0x02, 0x60, 0x03]),   # status command
        response=True
    )
    await asyncio.sleep(0.2)
    
    
    
async def load_services(client):
    print("📡 waiting for gatt services...")
    for _ in range(20):   # 최대 2초 대기
        if client.services: break
        await asyncio.sleep(0.1)

    if not client.services:
        raise RuntimeError("GATT services not loaded")

    for service in client.services:
        print(f"🔧 {service.uuid}")
        for char in service.characteristics:
            print(f"   📎 {char.uuid} | {char.properties}")
    print("✅ services ready")

# ================================
# 연결 시퀀스 (Windows 최적화)
# ================================


async def wait_until_connected(client, timeout=5):
    for _ in range(int(timeout * 10)):
        if client.is_connected:
            return True
        await asyncio.sleep(0.1)
    return False



async def connect_nordic(address):
    client = BleakClient(address, use_cached=False)
    await client.connect()
    
    ok = await wait_until_connected(client)
    if not ok:
        raise RuntimeError("BLE link not ready")

    # Windows 안정화 버퍼
    await load_services(client)
    # UART open
    await client.write_gatt_char(
        WRITE_UUID,
        b'\x02\x60\x03',
        response=True
    )
    await asyncio.sleep(0.5)


    await asyncio.sleep(0.2)

    return client


# ================================
# 명령 전송
# ================================
async def send_cmd(client, cmd):
    unit = "kg" # lb
    buzzer = True
    
    unit = 0x30 if unit == "kg" else 0x31
    buzzer = 0x30 if buzzer == False else 0x31
    

    commands = {
        "status":  bytearray([0x02,0x60,0x03]),
        "setup":   bytearray([0x02,0x61,unit,0x1B,buzzer,0x1B,0x03]),
        "result":  bytearray([0x02,0x62,0x03]),
        "reset":   bytearray([0x02,0x63,0x03]),
        "poweroff":bytearray([0x02,0x70,0x03]),
    }

    if cmd not in commands:
        print("❌ unknown cmd")
        return

    await client.write_gatt_char(
        WRITE_UUID,
        commands[cmd],
        response=True
    )

    print(">>> sent:", cmd)


# ================================
# 메인 루프
# ================================
def noti_handler(sender, data):
    print("<<<", " ".join(f"{b:02X}" for b in data))


async def main():

    address = None
    while not address:
        address = await find_device()
        await asyncio.sleep(1)

    while True:
        try:
            client = await connect_nordic(address)
            await client.start_notify(NOTIFY_UUID, noti_handler)
            print("📡 notify active")

            while True:
                cmd = await asyncio.to_thread(input, "cmd (status/setup/result/reset/exit): ")

                if cmd == "exit":
                    await client.disconnect()
                    return

                await send_cmd(client, cmd)

        except Exception as e:
            print("💥 disconnected, retrying...", e)
            await asyncio.sleep(1)


# ================================
asyncio.run(main())
