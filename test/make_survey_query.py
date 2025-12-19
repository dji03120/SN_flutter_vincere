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





def insert_question(survey_id, question_no, form_type, title, answer_items):
    print(survey_id, question_no, title, form_type)
    sql = """
    INSERT INTO mst_survey_question
    (SURVEY_ID, QUESTION_ID, FORM_TYPE, QUESTION, ANSWER_ITEMS)
    VALUES (%s, %s, %s, %s, %s)
    """
    return execute(sql, (
        survey_id,
        question_no,
        form_type,
        title,
        json.dumps({"items": answer_items}, ensure_ascii=False, indent=2)
    ))

def update_answer_items(question_id, answer_items):
    sql = """
    UPDATE mst_survey_question
    SET ANSWER_ITEMS = %s
    WHERE ID = %s
    """
    execute(sql, (
        json.dumps({"items": answer_items}, ensure_ascii=False, indent=2),
        question_id
    ))






def parse_question(q, question_no, survey_id):

    # main quesiton
    answer_items = []
    if q.get("type"):
        for idx, opt in enumerate(q.get("options", []), start=1):
            answer_items.append({
                "id": idx,
                "text": opt,
                "show_if_id": None, 
            })

    # insert 
    parent_id = insert_question(
        survey_id,
        question_no,
        q.get("type","none"),
        q["title"],
        answer_items
    )


    # sub questions iterator
    for sub in q.get("subQuestions", []):
        sub_id = parent_id
        sub_items = []
        for item in sub.get("subItems", []):

            sub_item = {
                "id": int(item["id"]),
                "text": item["label"],
                "input": {
                    "type": "text" if item.get("input", 0) else None,
                    "unit": item.get("unit", "")
                },
                "show_if_id": item.get("show_if", parent_id), 
            }
            sub_items.append(sub_item)

            # ===== 3. detailSubQuestions =====
            for detail in item.get("detailSubQuestions", []):
                detail_items = []
                if detail["detailSubType"] == "radio":
                    for i, o in enumerate(detail["detailUnit"].split("|"), 1):
                        detail_items.append({
                            "id": i,
                            "text": o,
                            "show_if_id": detail.get("show_if", sub_id), 
                        })

                detail_id = insert_question(
                    survey_id,
                    question_no,
                    detail.get("detailSubType","none"),
                    detail["detailSubTitle"],
                    detail_items
                )
                sub_item[0] = detail_id

        # ===== 4. subQuestion INSERT =====
        sub_id = insert_question(
            survey_id,
            question_no,
            sub.get("subType","none"),
            sub["subTitle"],
            sub_items
        )

    # ===== 6. 메인 질문 UPDATE =====
    update_answer_items(parent_id, answer_items)
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