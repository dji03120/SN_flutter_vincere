


def calculate_bfp_kushner(weight, height, age, sex, impedance):
    """
    Kushner 공식으로 체지방률 계산
    weight: 체중 (kg)
    height: 키 (cm)
    age: 나이
    sex: "male" 또는 "female"
    impedance: 임피던스 (Ω)
    """
    sex_value = 1 if sex.lower() == "male" else 0

    # FFM 계산
    impedance = impedance/1000*1.54
    ffm = 0.00085 * (height ** 2 / impedance) + 0.14 * weight + 0.25 * age + 2.2 * sex_value

    # 체지방률 계산
    bfp = weight - ffm
    return round(bfp,3)


# 예제
weight = 73
height = 168
age = 28
sex = "male"
impedance = 618

bfp = calculate_bfp_kushner(weight, height, age, sex, impedance)
print("Kushner 공식 체지방률:", bfp, "%")




import pymysql
import json

conn = pymysql.connect(host="203.251.89.161", user="vincere_id", password="vincere_pw", db="vincere_db")
cursor = conn.cursor(pymysql.cursors.DictCursor)
cursor.execute("SELECT * FROM mst_body_ref")
rows = cursor.fetchall()

result = {}
for row in rows:
    std = row['standard_gbn']
    gender = row['gender_gbn']
    if std not in result:
        result[std] = {}
    if gender not in result[std]:
        result[std][gender] = {}
    
    try:
        grades = [float(row['grade_2_start']), float(row['grade_3_start']), float(row['grade_4_start']), float(row['grade_5'])]
    except:
        print(row)
        input(">>")
    result[std][gender][row['age_end']] = grades
    
    
for key in result:
    print(key, 'F')
    for key2 in result[key]['F']:
        print(f'"{key2}":{result[key]["F"][key2]},')
    print(key, 'M')
    for key2 in result[key]['M']:
        print(f'"{key2}":{result[key]["M"][key2]},')

#json_output = json.dumps(result, ensure_ascii=False, indent=2)
#print(json_output)