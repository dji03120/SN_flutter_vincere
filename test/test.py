


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
