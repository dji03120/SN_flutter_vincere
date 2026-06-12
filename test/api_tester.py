import requests


prd = "https://vincerebiohealth.kr/root"
dev = "http://127.0.0.1:8080"
url = prd

if 0:
    res = requests.post(f"{url}/app/getWorkoutList.do",json={
        "user_id" : "tester",
    })
    print(res.content)

if 0:
    res = requests.post(f"{url}/app/selectWorkoutRecent.do",json={
        "user_id" : "tester",
    })
    print(res.content)


if 0:
    res = requests.post(f"{url}/app/registerWorkout.do",json={
        "user_id" : "1",
        "device_id": "1",
        "meta_data": {'test':'1234'}
    })
    print(res.content)

if 0:
    res = requests.post(f"{url}/app/updateWorkoutEndTime.do",json={
        "user_id" : "1"
    })
    print(res.content)
    
    
if 0:
    res = requests.post(f"{url}/app/updateWorkout.do",json={
        "user_id" : "tester",
        "meta_data": {"test":1234}
    })
    print(res.content)


if 0:
    import json
    url = "https://vincerebiohealth.kr/api/vincere"
    res = requests.post(f"{url}/select-user-health",json={
        "user_id" : "tester",
    }, verify=False)
    print(json.loads(res.content))
    
if 0:
    import json
    url = "https://vincerebiohealth.kr/api/vincere"
    res = requests.post(f"{url}/update-user-health",json={
        "user_id" : "tester",
        "item_nm" :"체지방률",
        "value": "50"
    }, verify=False)
    print(json.loads(res.content))

if 1:
    api_key = "zPkSTulXlcw4UKXo9YQS1n7lus1sOEnXVkG727sY2ck9wZ8YPQxehyPAf2pg9FhdITGSZx7aW8tTl2jqLcNivvSuPOW2xW8r5KnTsRMfxqgy0emq0SSdzNtGQ6hIVi3w"
    url = "https://api.thefitrus.com/fitrus-ml/measure/bodyfat"
    headers = {
        "Content-Type": "application/json", 
        "x-api-key": api_key
    }
    payload = {
        "age": "28",
        "gender": "male",
        "height": "168",
        "voltage": "1.278",
        "weight": "72.5"
    }
    #payload = {'age': 27, 'gender': 'male', 'height': 168, 'voltage': 1.25, 'weight': 73};
    response = requests.post(url, headers=headers, json=payload)
    print(response.content)
    
    
    
if 0:
    api_key = "zPkSTulXlcw4UKXo9YQS1n7lus1sOEnXVkG727sY2ck9wZ8YPQxehyPAf2pg9FhdITGSZx7aW8tTl2jqLcNivvSuPOW2xW8r5KnTsRMfxqgy0emq0SSdzNtGQ6hIVi3w"
    url = "https://api.thefitrus.com/fitrus-ml/measure/stress"
    url = "https://api.thefitrus.com/fitrus-ml/measure/hr"
    headers = {
        "Content-Type": "application/json", 
        "x-api-key": api_key
    }
    payload = {
        "birth": "28",
        "ppgdata": "male",
    }
    #payload = {'age': 27, 'gender': 'male', 'height': 168, 'voltage': 1.25, 'weight': 73};
    response = requests.post(url, headers=headers, json=payload)
    print(response.content)
    
    
    
if 0:
    import requests, json
    url = "https://vincerebiohealth.kr/root"
    res = requests.post(f"{url}/app/getUserGrades.do",json={
        'userId': 'tester',
        'bym': '19980915',
    }, verify=False)
    print(res.content)
    
    
    
    
    
    
    
    
def b3int(b1, b2, b3): return (b1 << 16) | (b2 << 8) | b3
def parse_ppg_bytes(arr: bytes):
    if len(arr) != 18:
        raise ValueError("Expected 18 bytes")

    values = []
    for i in range(0, len(arr), 3):
        value = b3int(arr[i], arr[i+1], arr[i+2])
        values.append(value)
        print(
            f"idx={i//3}, "
            f"bytes={[arr[i], arr[i+1], arr[i+2]]}, "
            f"value={value}" )
    return values

raw = bytes([
    0x01, 0x02, 0x03,
    0x04, 0x05, 0x06,
    0x07, 0x08, 0x09,
    0x0A, 0x0B, 0x0C,
    0x0D, 0x0E, 0x0F,
    0x10, 0x11, 0x12,
])

values = parse_ppg_bytes(raw)
api_key = "zPkSTulXlcw4UKXo9YQS1n7lus1sOEnXVkG727sY2ck9wZ8YPQxehyPAf2pg9FhdITGSZx7aW8tTl2jqLcNivvSuPOW2xW8r5KnTsRMfxqgy0emq0SSdzNtGQ6hIVi3w"
url = "https://api.thefitrus.com/fitrus-ml/measure/stress"
#url = "https://api.thefitrus.com/fitrus-ml/measure/hr"
headers = {
    "Content-Type": "application/json",
    "x-api-key": api_key
}

payload = {
    "list": values*1000,  # ppg 데이터를 넣으라고 하는데 1차 배열
    "age":30
}
response = requests.post(url, headers=headers, json=payload)

print(response.status_code)
try:
    print(response.json())
except:
    print(response.content)



