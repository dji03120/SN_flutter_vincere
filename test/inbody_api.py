import requests

url = "https://apikr.lookinbody.com/InBody/GetInBodyData"
headers = {
    "Account": "vincere",
    "API-KEY": "tTI2o6Wodn0QkBlvPvKRNC/C8SqTxY+F3CjQ3aR65C0=",
    "Content-Type": "application/json; charset=utf-8"
}

payload = {
    "UserPhone": "01092951532",
    "StartDate": "2026-01-01",
    "EndDate": "2026-05-31"
}
response = requests.post(url, headers=headers, json=payload)
print(response.content)