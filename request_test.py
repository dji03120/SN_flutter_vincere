import requests


"""
    // 운동 기록 등록
    public int insertWorkout(String user_id, String device_id, Map<String, Object> meta_data ) throws DataAccessException {
        Map<String, Object> param_map = new HashMap<>();
        param_map.put("user_id", user_id);
        param_map.put("device_id", device_id);
        param_map.put("meta_data", meta_data); // JSON 형태를 Map으로 전달
        return update("WORKOUT_MAPPER.insertWorkout", param_map);
    }
"""

prd = "https://vincerebiohealth.kr/root"
dev = "http://127.0.0.1:8080"
url = prd

if 0:
    res = requests.post(f"{url}/app/getWorkoutList.do",json={
        "user_id" : 1,
    })
    print(res.content)


if 0:
    res = requests.post(f"{url}/app/registerWorkout.do",json={
        "user_id" : "1",
        "device_id": "1",
        "meta_data": {'test':'1234'}
    })
    print(res.content)

if 1:
    res = requests.post(f"{url}/app/updateWorkoutEndTime.do",json={
        "user_id" : "1"
    })
    print(res.content)
    