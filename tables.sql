-------------------------------------------------------
-- 1. users (사용자 기본 정보)
-------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nickname TEXT NOT NULL,
    gender TEXT,
    marketing_agree BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 테이블 설명
COMMENT ON TABLE users IS '사용자 기본 정보 및 데이터 수집 동의 여부 관리';

-- 컬럼 설명
COMMENT ON COLUMN users.user_id IS '사용자 고유 식별자 (UUID)';
COMMENT ON COLUMN users.nickname IS '사용자 닉네임 (비실명 처리)';
COMMENT ON COLUMN users.gender IS '성별 (M: 남성, F: 여성, Etc: 기타) - 매칭 기초 데이터';
COMMENT ON COLUMN users.marketing_agree IS '데이터 수집 및 이용 동의 여부 (TRUE일 경우에만 데이터 활용)';
COMMENT ON COLUMN users.created_at IS '사용자 데이터 최초 생성 일시';


-------------------------------------------------------
-- 2. game_sessions (게임 한 판의 결과 및 분석)
-------------------------------------------------------
CREATE TABLE IF NOT EXISTS game_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(user_id) ON DELETE CASCADE,
    final_choice TEXT,
    my_persona JSONB,
    ideal_preference JSONB,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 테이블 설명
COMMENT ON TABLE game_sessions IS '게임 플레이 세션 정보 (성향 분석 결과 및 최종 선택 포함)';

-- 컬럼 설명
COMMENT ON COLUMN game_sessions.session_id IS '세션 고유 ID (게임 한 판 단위)';
COMMENT ON COLUMN game_sessions.user_id IS '플레이한 사용자 ID (users 테이블 참조)';
COMMENT ON COLUMN game_sessions.final_choice IS '유저가 최종 선택한 AI 파트너 (예: PARTNER_A, PARTNER_B) - 라벨링 데이터';
COMMENT ON COLUMN game_sessions.my_persona IS 'LLM이 분석한 [나의 연애 성향] (JSON 구조: 키워드, 점수 등)';
COMMENT ON COLUMN game_sessions.ideal_preference IS 'LLM이 분석한 [나의 이상형 선호도] (JSON 구조: 선호 성격, 보완점 등)';
COMMENT ON COLUMN game_sessions.played_at IS '게임 플레이 완료 시간';


-------------------------------------------------------
-- 3. chat_logs (대화 상세 내역)
-------------------------------------------------------
CREATE TABLE IF NOT EXISTS chat_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID REFERENCES game_sessions(session_id) ON DELETE CASCADE,
    partner_type TEXT,
    chat_history JSONB,
    turn_count INT DEFAULT 0
);

-- 테이블 설명
COMMENT ON TABLE chat_logs IS 'AI 파트너와의 상세 대화 로그 (Raw Data)';

-- 컬럼 설명
COMMENT ON COLUMN chat_logs.log_id IS '대화 로그 고유 ID';
COMMENT ON COLUMN chat_logs.session_id IS '해당 대화가 발생한 게임 세션 ID';
COMMENT ON COLUMN chat_logs.partner_type IS '대화 상대 AI의 타입 (예: SIMILAR-유사형, OPPOSITE-반대형, RANDOM)';
COMMENT ON COLUMN chat_logs.chat_history IS '대화 내용 전체 원문 (OpenAI API 포맷의 JSON 리스트)';
COMMENT ON COLUMN chat_logs.turn_count IS '총 대화 턴 수 (데이터 몰입도 및 품질 판단 지표)';

-- analysis_results 테이블: 대화 분석 결과 저장
-- 사용자의 연애 스타일, 호환성, 인사이트 등 LLM 분석 결과를 저장합니다.
-- analysis_results 테이블: 대화 분석 결과 저장
-- [수정됨] session_id 타입을 INTEGER -> UUID로 변경

CREATE TABLE analysis_results (
    analysis_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),   -- SERIAL 대신 UUID 사용 권장
    session_id UUID NOT NULL,                                 -- [핵심 수정] INTEGER -> UUID로 변경
    
    -- 사용자 연애 스타일 분석
    style VARCHAR(100),
    user_type VARCHAR(20),
    keywords JSONB,
    strength TEXT,
    weakness TEXT,
    
    -- 호환성 분석
    best_match VARCHAR(20),
    best_reason TEXT,
    similar_style VARCHAR(20),
    similar_chemistry TEXT,
    opposite_style VARCHAR(20),
    opposite_chemistry TEXT,
    
    -- 인사이트
    positive TEXT,
    improvement TEXT,
    dating_tip TEXT,
    warning TEXT,
    
    -- 전체 요약
    summary TEXT,
    
    -- 메타데이터
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 외래 키 제약 (이제 타입이 맞아서 에러가 안 납니다)
    CONSTRAINT fk_session FOREIGN KEY (session_id) REFERENCES game_sessions(session_id) ON DELETE CASCADE
);

-- 인덱스 생성
CREATE INDEX idx_analysis_session_id ON analysis_results(session_id);

-- 테이블 설명
COMMENT ON TABLE analysis_results IS 'LLM 대화 분석 결과를 저장하는 테이블';
COMMENT ON COLUMN analysis_results.analysis_id IS '분석 결과 고유 ID (UUID)';
COMMENT ON COLUMN analysis_results.session_id IS '게임 세션 ID (UUID, game_sessions 참조)';
COMMENT ON COLUMN analysis_results.style IS '사용자의 대화 스타일 (예: 적극적인 리액션러)';
COMMENT ON COLUMN analysis_results.user_type IS '사용자가 가장 가까운 타입 (EMOTIONAL/LOGICAL/TOUGH)';
COMMENT ON COLUMN analysis_results.keywords IS '사용자 스타일 키워드 배열';
COMMENT ON COLUMN analysis_results.strength IS '연애에서의 강점';
COMMENT ON COLUMN analysis_results.weakness IS '연애에서 보완할 점';
COMMENT ON COLUMN analysis_results.best_match IS '가장 잘 맞는 상대 타입';
COMMENT ON COLUMN analysis_results.best_reason IS '가장 잘 맞는 이유';
COMMENT ON COLUMN analysis_results.similar_style IS '비슷한 스타일의 상대 타입';
COMMENT ON COLUMN analysis_results.similar_chemistry IS '비슷한 스타일 케미 분석';
COMMENT ON COLUMN analysis_results.opposite_style IS '반대 스타일의 상대 타입';
COMMENT ON COLUMN analysis_results.opposite_chemistry IS '반대 스타일 케미 분석';
COMMENT ON COLUMN analysis_results.positive IS '대화에서 보인 긍정적인 모습';
COMMENT ON COLUMN analysis_results.improvement IS '개선하면 좋을 점';
COMMENT ON COLUMN analysis_results.dating_tip IS '실제 연애에서 활용할 팁';
COMMENT ON COLUMN analysis_results.warning IS '주의해야 할 패턴';
COMMENT ON COLUMN analysis_results.summary IS '전체 분석 요약';
COMMENT ON COLUMN analysis_results.created_at IS '분석 결과 생성 시간';



-------------------------------------------------------
-- 4. affinity_logs (실시간 호감도 변경 로그)
-------------------------------------------------------
CREATE TABLE IF NOT EXISTS affinity_logs (
    log_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,    
    partner_type TEXT NOT NULL,    -- 어떤 상대방과의 대화인가? -- 예: 'EMOTIONAL', 'LOGICAL', 'TOUGH'
    turn_index INTEGER NOT NULL,   -- 대화의 어느 시점인가? -- 몇 번째 대화 턴인지 (1, 2, 3...)
    -- 점수 데이터
    score_change INTEGER NOT NULL, -- 이번 턴의 변화량 (예: +10, -5)
    current_score INTEGER NOT NULL,-- 변화 후 누적 점수 (0 ~ 100)
    -- 분석 데이터
    reason TEXT,                   -- 점수 변경 사유 (예: "공감하는 리액션을 보여줘서 호감 상승")
    trigger_message TEXT,          -- (선택) 점수 변화를 유발한 유저의 실제 메시지 요약
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    -- 외래 키 제약 조건
    CONSTRAINT fk_affinity_session FOREIGN KEY (session_id) REFERENCES game_sessions(session_id) ON DELETE CASCADE
);

-- 인덱스 생성 (세션별, 파트너별 조회 성능 최적화)
CREATE INDEX idx_affinity_session_partner ON affinity_logs(session_id, partner_type);

-- 테이블 설명
COMMENT ON TABLE affinity_logs IS '대화 턴마다 발생하는 호감도 변화 및 원인을 기록하는 테이블';

-- 컬럼 설명
COMMENT ON COLUMN affinity_logs.log_id IS '로그 고유 ID';
COMMENT ON COLUMN affinity_logs.session_id IS '게임 세션 ID (game_sessions 참조)';
COMMENT ON COLUMN affinity_logs.partner_type IS '대화 상대 타입 (EMOTIONAL/LOGICAL/TOUGH)';
COMMENT ON COLUMN affinity_logs.turn_index IS '현재 대화가 몇 번째 턴인지 표시';
COMMENT ON COLUMN affinity_logs.score_change IS '직전 점수 대비 변화량 (예: +5, -10)';
COMMENT ON COLUMN affinity_logs.current_score IS '변화가 반영된 현재 총 호감도 (0~100)';
COMMENT ON COLUMN affinity_logs.reason IS 'AI가 판단한 호감도 변화의 구체적인 이유';
COMMENT ON COLUMN affinity_logs.trigger_message IS '호감도 변화를 유발한 사용자의 메시지 내용';