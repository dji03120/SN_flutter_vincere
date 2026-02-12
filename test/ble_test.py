import asyncio
from bleak import BleakScanner, BleakClient
import datetime

DEVICE_NAME = "BP170B_160B 4722"

WRITE_UUID  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"   # RX
NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"   # TX

# ================================
# UART 수신 핸들러
# ================================
def noti_handler(sender, data):
    print("<<<", " ".join(f"{b:02X}" for b in data))

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

# ================================
# Protocol command 빌드
# ================================
def build_command(cmd0, cmd1, data):
    body0 = ((len(data) + 2) & 0x3F) + 0x0A
    body1 = (((len(data) + 2) >> 6) & 0x3F) + 0x0A
    cmd = bytearray([0x02, 0x42])   # STX, ID
    cmd += bytearray([body0, body1]) # Length
    cmd += bytearray([cmd0, cmd1])   # Command
    cmd += data                      # Data
    checksum = (sum(cmd[1:]) & 0x3F) + 0x0A
    cmd += bytearray([checksum, 0x03])  # checksum, ETX
    return cmd

def build_datetime_bytes(year, month, day, hour, minute):
    return bytearray([
        (year - 2000) + 0x0A,
        month + 0x0A,
        day + 0x0A,
        hour + 0x0A,
        minute + 0x0A
    ])

# ================================
# 명령 전송
# ================================
async def send_cmd(client, cmd):
    empty = bytearray([])
    now = datetime.datetime.now()
    timebytes = build_datetime_bytes(now.year, now.month, now.day, now.hour, now.minute)
    commands = {
        "status_time":  build_command(0xC0, 0x00, empty),
        "status_m1":    build_command(0xC0, 0x01, empty),
        "status_m2":    build_command(0xC0, 0x02, empty),
        "status_last":  build_command(0xC0, 0x03, empty),
        "status_is_running": build_command(0xC0, 0x04, empty),
        "status_is_complate": build_command(0xC0, 0x05, empty),
        "time": build_command(0xB1, 0xB0, timebytes),
        "log": build_command(0xCA, 0x00, empty)
    }
    if cmd not in commands:
        print("❌ unknown cmd")
        return
    await client.write_gatt_char(WRITE_UUID, commands[cmd], response=True)
    print(">>> sent:", cmd)

# ================================
# 메인 루프
# ================================
async def main():
    address = None
    while not address:
        address = await find_device()
        await asyncio.sleep(1)

    try:
        async with BleakClient(address) as client:
            # notify 활성화
            await client.start_notify(NOTIFY_UUID, noti_handler)
            
            # UART 깨우기
            await client.write_gatt_char(WRITE_UUID, build_command(0x60, 0x00, bytearray([])), response=True)
            
            # 시간 전송
            now = datetime.datetime.now()
            timebytes = build_datetime_bytes(now.year, now.month, now.day, now.hour, now.minute)
            await client.write_gatt_char(WRITE_UUID, build_command(0xB1,0xB0,timebytes), response=True)

            print("📡 BLE 연결 및 notify 활성화 완료!")

            while True:
                cmd = await asyncio.to_thread(input, "cmd (status_time/log/exit): ")
                if cmd == "exit":
                    break
                await send_cmd(client, cmd)

    except Exception as e:
        print("💥 BLE 연결 실패:", e)

# ================================
asyncio.run(main())
