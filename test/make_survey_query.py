import json
import uuid
import pymysql
DB_CONFIG = {
    "host": "203.251.89.161",
    "port": 3306,
    "user": "vincere_id",
    "password": "vincere_pw",
    "database": "vincere_db",
    "charset": "utf8mb4",
    "autocommit": False,
    "cursorclass": pymysql.cursors.DictCursor
}
Q_NO = 1

def select(sql):
    conn = pymysql.connect(**DB_CONFIG)
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql)
            rows = cursor.fetchall()
            return rows
    finally:
        conn.close()



def execute(sql, params=None):
    conn = pymysql.connect(**DB_CONFIG)
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params)
            conn.commit()
            return cursor.lastrowid
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()





def insert_question(survey_id, item_id, form_type, question_type,  title, answer_items, minWidth):
    print(survey_id, title, form_type, item_id)
    sql = """
    INSERT INTO mst_survey_question
    (SURVEY_ID, QUESTION_ID, FORM_TYPE, QUESTION_TYPE, QUESTION, ANSWER_ITEMS)
    VALUES (%s, %s, %s, %s, %s, %s)
    """
    return execute(sql, (
        survey_id,
        item_id,
        form_type,
        question_type,
        title,
        json.dumps({"items": answer_items, "minWidth": minWidth}, ensure_ascii=False, indent=2)
    ))

def update_sub_question_cond(question_id, sub_question_cond):
    sql = """
    UPDATE mst_survey_question
    SET SUB_QUESTION_COND = %s
    WHERE ID = %s
    """
    execute(sql, (
        json.dumps({"sub_question_cond": sub_question_cond}, ensure_ascii=False, indent=2),
        question_id
    ))






def parse_question(q, question_no, survey_id):

    question_id = f"{question_no}"
    
    # main quesiton
    answer_items = []
    if q.get("type"):
        for idx, opt in enumerate(q.get("options", []), start=1):
            answer_items.append({
                "id": idx,
                "text": opt,
            })
    # insert main question
    parent_question_sub_cond = []
    parent_id = insert_question(
        survey_id,
        question_id,
        q.get("type","none"),
        "ROOT",
        q["title"],
        answer_items,
        0
    )

    # sub questions iterator
    for sub_q_no, sub in enumerate(q.get("subQuestions", [])): # 하위 질문
        sub_items = []
        sub_question_id = question_id+f"-{sub_q_no+1}"
        for item in sub.get("subItems", []):
            sub_items.append({
                "id": int(item["id"]),
                "text": item["label"],
                "type": "text" if item.get("input", 0) else None, 
                "unit": item.get("unit", ""),
                "input": item.get("input", ""),
                "inItemType": item.get("inItemType", ""),
                "items": item.get("items", ""),
            })
        sub_question_sub_cond = []
        sub_id = insert_question(
            survey_id,
            sub_question_id,
            sub.get("subType","none"),
            "SUB",
            sub["subTitle"],
            sub_items,
            sub.get("subMinWidth",0),
            
        )
        
        parent_question_sub_cond.append(
            {"id":sub_id, "value":sub.get("show_if",{"value":""})["value"]}
        )

        for _, item in enumerate(sub.get("subItems", [])):
            for detail_q_no, detail in enumerate(item.get("detailSubQuestions", [])):
                detail_question_id = sub_question_id+f"-{detail_q_no+1}"
                detail_items = []
                if "detailUnit" in detail:
                    for i, o in enumerate(detail["detailUnit"].split("|"), 1):
                        detail_items.append({
                            "id": i,
                            "text": o,
                            "type": "text" if item.get("input", 0) else None, 
                            "unit": item.get("unit", ""),
                            "input": item.get("input", ""),
                            "inItemType": item.get("inItemType", ""),
                            "items": item.get("items", ""),
                        })
                else:
                    detail_items.append({})
                detail_id = insert_question(
                    survey_id,
                    detail_question_id,
                    detail.get("detailSubType","none"),
                    "SUB",
                    detail["detailSubTitle"],
                    detail_items,
                    detail.get("detailItemMinWidth",0),
                )
                value = detail.get("show_if",{"value":""})["value"]
                if value not in [_item['label'] for _item in sub.get("subItems", []) if 'label' in item]:
                    # 선택됨일 경우 선택지에는 없음, item내역에서 체크 후에 저장 필요
                    value = item['label']
                    
                sub_question_sub_cond.append( {"id":detail_id, "value":value} )
                update_sub_question_cond(detail_id,[])
        update_sub_question_cond(sub_id,sub_question_sub_cond)
    update_sub_question_cond(parent_id,parent_question_sub_cond)
    return question_no







    
def main():
    conn = pymysql.connect(**DB_CONFIG)
    try:
        with conn.cursor() as cursor:
            cursor.execute("SELECT id, surveyContent FROM mst_survey")
            rows = cursor.fetchall()

        for row in rows:
            survey_id = row["id"]
            data = json.loads(row["surveyContent"])

            question_no = 1
            for q in data["questions"]:
                parse_question(q, question_no , survey_id)
                question_no += 1

    finally:
        conn.close()

if __name__ == "__main__":
    main()