import asyncio
from bleak import BleakScanner, BleakClient
import datetime

DEVICE_NAME = "BP170B_160B 4723"
NUS_SERVICE = "6e400001-b5a3-f393-e0a9-e50e24dcca9e"
WRITE_UUID  = "6e400002-b5a3-f393-e0a9-e50e24dcca9e"
NOTIFY_UUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"

# ================================
# notify 핸들러
# ================================
def noti_handler(sender, data):
    print("<<< notify:", " ".join(f"{b:02X}" for b in data))

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
# Protocol Frame 빌드
# ================================
def build_command(cmd0, cmd1, data):
    body0 = ((len(data) + 2) & 0x3F) + 0x0A
    body1 = (((len(data) + 2) >> 6) & 0x3F) + 0x0A
    cmd = bytearray([0x02, 0x42])               # STX, ID
    cmd += bytearray([body0, body1])            # Length
    cmd += bytearray([cmd0, cmd1])              # Command
    cmd += data                                 # Data
    checksum = (sum(cmd[1:]) & 0x3F) + 0x0A    # ID 포함 이후
    cmd += bytearray([checksum, 0x03])          # checksum, ETX
    return cmd

def build_datetime_bytes(year, month, day, hour, minute):
    y = (year - 2000) & 0xFF
    return bytearray([
        y + 0x0A,
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
        "time_sync":            build_command(0xB1, 0xB0, timebytes),
        "status":     build_command(0xC0, 0x00, empty),
        "log":             build_command(0xCA, 0x00, empty),
    }

    if cmd not in commands:
        print("❌ unknown cmd")
        return

    # response=True 로 안정성 확보
    await client.write_gatt_char(WRITE_UUID, commands[cmd], response=True)
    print(">>> sent:", cmd)

# ================================
# 연결 및 notify 활성화
# ================================
async def connect_device(address):
    client = BleakClient(address, use_cached=False)
    await client.connect()

    # Windows BLE 안정화
    await asyncio.sleep(0.3)

    # notify 먼저 설정
    await client.start_notify(NOTIFY_UUID, noti_handler)
    await asyncio.sleep(0.2)

    # UART 깨우기 (status command)
    await client.write_gatt_char(WRITE_UUID, build_command(0x60, 0x00, bytearray([])), response=True)
    await asyncio.sleep(0.2)

    # 시간 전송 (장치 초기화)
    now = datetime.datetime.now()
    timebytes = build_datetime_bytes(now.year, now.month, now.day, now.hour, now.minute)
    await client.write_gatt_char(WRITE_UUID, build_command(0xB1, 0xB0, timebytes), response=True)
    await asyncio.sleep(0.2)

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


# status
# cmd (status_time/log/exit): <<< notify: 02 42 0D 0A B0 00 13 26 03 // ready
# cmd (status_time/log/exit): <<< notify: 02 42 0D 0A B0 00 0E 21 03 // running
# cmd (status_time/log/exit): <<< notify: 02 42 0D 0A B0 00 0F 22 03 // end