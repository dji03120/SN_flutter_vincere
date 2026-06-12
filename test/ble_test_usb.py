import serial
import time
import threading

# COM 포트와 속도 설정 (USB DFU dongle 연결된 포트로 변경)
COM_PORT = "COM5"  # Windows 예시, macOS/Linux는 '/dev/ttyACM0'
BAUDRATE = 115200

# 명령 목록
COMMANDS = {
    "bfp_start": "*BFP:Start#\r\n",
    "bfp_stop": "*BFP:Stop#\r\n",
    "cal_start": "*Calmode:Start#\r\n",
    "cal_stop": "*Calmode:Stop#\r\n",
    "spo2_start": "*SpO2:Start#\r\n",
    "spo2_stop": "*SpO2:Stop#\r\n",
    "stress_start": "*Stress:Start#\r\n",
    "stress_stop": "*Stress:Stop#\r\n",
    "temp_start": "*Temp:Start#\r\n",
    "temp_body_start": "*Temp.Body:Start#\r\n",
    "info": "*Dev.Info:Read#\r\n",
    "battery": "*Dev.Info:Batt.Read#\r\n",
}

# 시리얼 연결
ser = serial.Serial(COM_PORT, BAUDRATE, timeout=0.5)

def read_thread():
    """백그라운드에서 USB 수신 데이터 읽기"""
    while True:
        if ser.in_waiting > 0:
            data = ser.read(ser.in_waiting)
            # 오른쪽 0 제거 후 UTF-8 변환
            data = data.rstrip(b'\x00')
            try:
                text = data.decode('utf-8', errors='ignore')
            except:
                text = data.hex()
            print(f"[Notify] {text}")

# 읽기 쓰레드 시작
threading.Thread(target=read_thread, daemon=True).start()

def send_command(cmd_key):
    if cmd_key not in COMMANDS:
        print("잘못된 명령")
        return
    data = COMMANDS[cmd_key].encode('utf-8')
    ser.write(data)
    print(f"[Send] {data.hex()} | {COMMANDS[cmd_key].strip()}")

if __name__ == "__main__":
    print("nRF USB 통신 테스트")
    print("명령 목록:", list(COMMANDS.keys()))
    print("종료하려면 'exit' 입력")

    while True:
        cmd = input("보낼 명령 선택: ").strip()
        if cmd == "exit":
            break
        send_command(cmd)

    ser.close()
    print("연결 종료")
