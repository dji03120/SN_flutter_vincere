import asyncio
from bleak import BleakScanner, BleakClient
from datetime import datetime
import traceback

import asyncio
from bleak import BleakScanner, BleakClient
from datetime import datetime
import traceback

# ================================
# UUID 설정
# ================================
MEASURE_NOTI = "00002a18-0000-1000-8000-00805f9b34fb"  # Glucose Measurement
CONTEXT_NOTI = "00002a34-0000-1000-8000-00805f9b34fb"  # Measurement Context
WRITE_UUID   = "0000fff1-0000-1000-8000-00805f9b34fb"  # Custom Profile Write/Notify
RACP_UUID    = "00002a52-0000-1000-8000-00805f9b34fb"  # RACP (Indicate/Write)
DEVICE_NAME  = "Auto-Chek 4178"

# ================================
# Notify/Indicate 핸들러
# ================================
def measure_noti_handler(sender, data):
    print(">>> Glucose Measurement:", ' '.join(f"{b:02X}" for b in data))

def context_noti_handler(sender, data):
    print(">>> Context Measurement:", ' '.join(f"{b:02X}" for b in data))

def custom_noti_handler(sender, data):
    print(">>> Custom Notify (Time Sync Response):", ' '.join(f"{b:02X}" for b in data))

def racp_handler(sender, data):
    print(">>> RACP Indicate (Record Response):", ' '.join(f"{b:02X}" for b in data))

# ================================
# BLE 장치 스캔
# ================================
async def scan_device():
    print("🔍 Scanning for BLE devices...")
    devices = await BleakScanner.discover()
    for d in devices:
        if d.name:
            print(d)
        if d.name == DEVICE_NAME:
            return d
    return None

# ================================
# 시간 동기화
# ================================
async def send_time_sync(client):
    now = datetime.now()
    year = now.year
    packet = bytearray([
        0xC0, 0x03, 0x01, 0x00,          # OpCode, Operator, Operand, Reserved
        year & 0xFF, (year >> 8) & 0xFF, # Year LSB/MSB
        now.month,
        now.day,
        now.hour,
        now.minute,
        now.second
    ])
    await client.write_gatt_char(WRITE_UUID, packet, response=True)
    print("✅ Time sync 명령 전송 완료")

# ================================
# RACP 모든 기록 조회
# ================================
async def request_all_records(client):
    # 0101 # all
    packet = bytearray([0x01, 0x01])  # OpCode=1 (Report Stored Records), Operator=1 (All Records)
    await client.write_gatt_char(RACP_UUID, packet, response=True)
    print("✅ RACP 모든 기록 요청 전송 완료")
    
async def request_records_count(client):
    # 0101 # all
    packet = bytearray([0x04, 0x01])  # OpCode=1 (Report Stored Records), Operator=1 (All Records)
    await client.write_gatt_char(RACP_UUID, packet, response=True)
    print("✅ RACP 모든 기록 요청 전송 완료")

# ================================
# 사용자 명령 루프
# ================================
async def user_loop(client):
    while True:
        cmd = await asyncio.to_thread(input, "명령 (time_sync, get_records, exit) : ")
        if cmd == "exit":
            break
        elif cmd == "time_sync":
            await send_time_sync(client)
        elif cmd == "get_records":
            await request_all_records(client)
        else:
            print("❌ 지원하지 않는 명령")

# ================================
# 메인 실행
# ================================
async def run():
    try:
        device = None
        while not device:
            device = await scan_device()
            if not device:
                await asyncio.sleep(0.5)
        address = device.address

        print("🔗 Connecting to:", address)
        async with BleakClient(address, use_cached=True) as client:

            # 페어링/인증
            paired = await client.pair(protection_level=2)
            print("🔒 Paired:", paired)

            # Notify/Indicate 구독
            await client.start_notify(MEASURE_NOTI, measure_noti_handler)
            await client.start_notify(CONTEXT_NOTI, context_noti_handler)
            await client.start_notify(WRITE_UUID, custom_noti_handler)  # Time Sync Notify
            await client.start_notify(RACP_UUID, racp_handler)           # RACP Indicate
            await asyncio.sleep(0.3)

            print("✅ Connected and notifications started")

            # 사용자 명령 루프
            await user_loop(client)

    except Exception:
        print(traceback.format_exc())

# ================================
# 실행
# ================================
asyncio.run(run())



"""
장치 전원 ON
PC에서 페어링 + Bonding

Bleak로 연결 (use_cached=True)
Custom Profile Write → Time Sync
RACP Write → Indicate 구독
Notify/Indicate 수신
필요시 기록 저장/삭제 명령
"""

"""
측정화면 (장치 단독 동작)
혈당 측정만 수행
장치가 자체 화면에서 측정 결과를 보여주거나 내부 메모리에 저장
BLE 전송 없음: 이 단계에서는 휴대폰 연동 화면을 열지 않으면 기록이 외부로 안 나감
블루투스 연동 화면 (휴대폰 앱 또는 노트북)
장치를 검색 → 선택 → 페어링 / PIN 입력
연결 성공 후, 전송 버튼 클릭 시 기록 전송
이때 RACP Write → Glucose/Context Notify → RACP Indicate 순으로 데이터가 전달됨
"""


"""
=> 0401
>>> RACP Indicate (Record Response): 05 00 01 00

=> 0101
>>> Glucose Measurement: 1B 01 00 EA 07 01 1C 0B 01 1C 00 00 75 B0 11 00 00
>>> RACP Indicate (Record Response): 06 00 01 01
>>> Context Measurement: 02 01 00 03


바이트	값	의미
0	1B	Flags = 0b00011011
1–2	01 00	Sequence Number = 1
3–4	EA 07	Year = 2026
5	01	Month = 1월
6	1C	Day = 28일
7	0B	Hour = 11시
8	01	Minute = 1분
9	1C	Second = 28초
0	Time Offset present	✅ 있음
1	Glucose + Sample location 있음	✅ 있음
2	단위 mol/L	❌ → kg/L (mg/dL 계열)
3	Sensor Status 있음	✅ 있음
4	Context follows	✅ 있음
Mantissa = 0x075 = 117
Exponent = 0xB = -5
117 × 10⁻⁵ = 0.00117 kg/L


# 순서 꼬인거 주의
찌르고 -> 피 좀 맺칠때 -> 꽂고 -> 빠르게 흡수(1초안에 안되면 실패)


[2명]
✅ RACP 모든 기록 요청 전송 완료
>>> Context Measurement: 02 01 00 03
>>> Glucose Measurement: 1B 01 00 EA 07 01 1C 0B 01 1C 00 00 75 B0 11 00 00
>>> Glucose Measurement: 0B 02 00 EA 07 01 1C 0B 12 09 00 00 71 B0 11 00 00
>>> RACP Indicate (Record Response): 06 00 01 01
>>> RACP Indicate (Record Response): 06 00 01 06
"""