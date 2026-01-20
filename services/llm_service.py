from openai import OpenAI
import streamlit as st
from config.settings import OPENAI_API_KEY, OPENAI_MODEL

# 클라이언트 초기화
if not OPENAI_API_KEY:
    # st.secrets에서 시도 (Streamlit Cloud 배포용)
    if "OPENAI_API_KEY" in st.secrets:
        client = OpenAI(api_key=st.secrets["OPENAI_API_KEY"])
    else:
        client = None
else:
    client = OpenAI(api_key=OPENAI_API_KEY)

import json

def get_ai_response(messages):
    """
    OpenAI API를 통해 챗봇 응답을 받아옵니다.
    messages: game_view에서 관리하는 대화 내역 리스트 (System Prompt 포함)
    Returns: dict {"response": str, "score": int}
    """
    if not client:
        return {"response": "🚨 API Key가 설정되지 않았습니다.", "score": 0}

    try:
        response = client.chat.completions.create(
            model=OPENAI_MODEL,
            messages=messages,
            response_format={"type": "json_object"} # JSON 모드 강제
        )
        content = response.choices[0].message.content
        return json.loads(content)
    except Exception as e:
        return {"response": f"🚨 오류 발생: {str(e)}", "score": 0}
