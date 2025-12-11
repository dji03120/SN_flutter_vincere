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
    import requests, json
    url = "https://vincerebiohealth.kr/root"
    res = requests.post(f"{url}/app/getUserGrades.do",json={
        'userId': 'tester',
        'bym': '19980915',
    }, verify=False)
    print(res.content)
    
    