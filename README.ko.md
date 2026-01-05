# Browser-Use Web View

[![BrowserUse](https://img.shields.io/badge/BrowserUse-0.11.2-black?style=flat&logo=github)](https://github.com/browser-use/browser-use)
![Python](https://img.shields.io/badge/Python-3.11-blue?style=flat&logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.116.1-success?style=flat&logo=fastapi)

Browser-Use Web View는 VNC/noVNC를 활용하여 browser-use 에이전트의 Headful 브라우저 화면을 웹 브라우저에서 실시간으로 확인할 수 있도록 설계된 컨테이너 기반 환경입니다. <br> vnc와 agent 컨테이너가 공유 X11 소켓으로 통신하며 세션 격리와 보안을 유지하는 구조로, 자동화된 브라우저의 동작을 가상 모니터로 안전하게 시각화합니다.

## 시스템 아키텍처

<img width="996" height="933" alt="473523324-d86b43ec-4204-4a94-ae86-01c63c39dfe1" src="https://github.com/user-attachments/assets/4431006a-1656-49ce-b97c-07b719b23743" />

### 멀티 세션 플로우
<img width="1138" height="570" alt="image" src="https://github.com/user-attachments/assets/8379e126-1940-4096-8857-3cdb141f4ad6" />


각 사용자가 browser-use task 실행을 요청하면 오케스트레이터가 새로운 세션 생성을 트리거합니다. 이때 개별 세션마다 VNC/agent 컨테이너 쌍이 독립적으로 기동되고, 해당 세션에 대해 noVNC를 통한 실시간 가상 모니터 화면이 제공됩니다. 각 세션은 Docker 네임스페이스와 전용 X11 소켓 볼륨을 기반으로 완전히 격리되어 실행되며, 이를 통해 세션 간 디스플레이 데이터가 안전하게 분리됩니다.

## 데모 영상

![vncsingle](https://github.com/user-attachments/assets/6468d96a-6f57-411f-9012-c39017110ff6)


#### 멀티 세션

![multisession](https://github.com/user-attachments/assets/f7d62f1d-575e-475a-8462-a9167ee1a9d6)


## Containers
### vnc

- **Xvfb**: 가상 디스플레이 서버 (예: :99)
- **x11vnc**: VNC 서버
- **websockify**: VNC를 WebSocket으로 변환하여 noVNC 접근 제공

### agent
- Browser-use Python 스크립트 실행 (예: `agent.py`)
- `vnc` 컨테이너와 X11 소켓 볼륨을 공유하여 가상 디스플레이에 출력 렌더링


## 시작하기

### 요구사항

- Docker & Docker Compose
- git
- Python 3.8 이상

### 1. 저장소 클론

```bash
git clone https://github.com/squatboy/browser-use-vnc.git
cd browser-use-vnc/
```

### 2. `.env` 파일 및 agent 스크립트 준비
- `agent/.env`: Browser-Use에 사용될 LLM API KEY 작성
- `agent/agent.py`: Browser-Use 에이전트 스크립트 파일
- `orchestrator/.env`: `PUBLIC_HOST=<서버의 공인 IP 또는 도메인>` 지정 (반드시 설정 필요, orchestrator가 noVNC 접속 URL 생성 시 사용)

> 이 파일들은 Docker Compose에 의해 자동으로 로드되어 agent 및 orchestrator 컨테이너를 구성하고 실행합니다.

### 3. Docker 이미지 사전 빌드

Orchestrator를 시작하기 전에 Docker 이미지를 미리 빌드하여 세션 생성 시 긴 지연을 방지하세요:

```bash
./prebuild.sh
```

이 스크립트는 VNC와 agent 이미지를 모두 빌드합니다. 완료되면 이미지가 이미 준비되어 있으므로 세션 생성이 훨씬 빨라집니다.

> **참고**: 이 스크립트를 실행하기 전에 Docker Desktop이 실행 중인지 확인하세요.

### 4. FastAPI Orchestrator 실행

1. **orchestrator 폴더에서 가상환경 생성 및 활성화**

```bash
cd orchestrator
python3 -m venv .venv
source .venv/bin/activate
```

2. **pip 업그레이드 및 requirements.txt 설치**

```bash
pip install -U pip
pip install -r requirements.txt
```

3. **uvicorn으로 서버 실행**

```bash
uvicorn app_orchestrator:app --host 0.0.0.0 --port 8000
```

### 5. 새 세션 생성

POST 요청을 보내 새로운 VNC/agent 세션을 생성합니다:

```bash
curl -X POST http://<Server-IP>:8000/sessions
```

응답에는 세션 ID와 동적으로 할당된 noVNC URL이 포함됩니다.

예시 응답:

```json
{
  "session_id": "1a2b3c4d",
  "novnc_url": "http://<Server-IP>:6081/vnc.html?autoconnect=true&resize=scale"
}
```

### 5. 세션 접속

제공된 URL을 웹 브라우저에서 열어 noVNC를 통해 가상 모니터에 접속합니다.

<br>

## 멀티 세션 수동 테스트 예시

오케스트레이션을 통해 사용하지 않고 직접 다른 `SESSION_ID`와 `NOVNC_PORT` 환경 변수를 지정하고 별도의 Docker Compose 프로젝트를 실행하여 여러 독립 세션을 수동으로 생성할 수 있습니다.

```bash
# 첫 번째 세션
cd vnc/
SESSION_ID=session1 NOVNC_PORT=6081 docker compose -p vnc1 up -d --build

# 두 번째 세션
SESSION_ID=session2 NOVNC_PORT=6082 docker compose -p vnc2 up -d --build
```

<img width="928" height="106" alt="image" src="https://github.com/user-attachments/assets/4b0ece57-77e8-4a11-90b6-ff77d1f8e726" />


그런 다음 세션에 각각 접속합니다:

- http://:6081/vnc.html
- http://:6082/vnc.html

<img width="743" height="97" alt="image" src="https://github.com/user-attachments/assets/643ce7ba-3434-491a-a302-398da8aa6aa4" />
<img width="743" height="97" alt="image" src="https://github.com/user-attachments/assets/e6fed99b-eb47-421e-a146-01e5d5ece702" />


각 세션은 고유한 X11 소켓 볼륨을 사용하므로 세션 간 데이터 누출 없이 격리됩니다.


## 보안 그룹 & 네트워크 설정

공용 서버에 배포할 경우, 세션에 필요한 noVNC 포트만 열어두세요 (예: 6080, 6081, 6082, ...). 필요에 따라 접근을 제한하는 것이 중요합니다.


## BrowserSession Python 설정 예시

Agent 컨테이너 내에서 브라우저를 실행할 때, 다음 설정을 사용하여 Docker 관련 일반적인 문제를 피하세요:

```python
browser_session = BrowserSession(
    headless=False,
    args=[
        "--no-sandbox",            # Docker에서 root로 실행할 때 필요
        "--disable-dev-shm-usage"  # 제한된 컨테이너 환경에서 /dev/shm 크래시 방지
    ],
)
```


## 커스터마이징 & 고급 사용법

- 시스템은 `vnc` 컨테이너(가상 디스플레이 및 VNC 서비스)와 `agent` 컨테이너(브라우저 자동화 스크립트)를 분리합니다.
- 자동화 워크플로우에 맞게 agent 스크립트(`agent.py`)를 확장하거나 수정할 수 있습니다.
- agent 컨테이너는 `vnc` 컨테이너가 관리하는 가상 디스플레이에 브라우저 출력을 렌더링하기 위해 공유된 X11 소켓 볼륨에 연결됩니다.


## 사용 사례: 웹사이트 내 VNC 데스크탑 임베딩

noVNC 웹 클라이언트를 iframe에 삽입하여 원격 데스크탑을 웹 애플리케이션에 직접 통합할 수 있습니다:

```html
<iframe
    src="http://<Server-IP>:6080/vnc.html?autoconnect=true"
    width="1280" height="720">
</iframe>
```


## 문제 해결 & 팁

- **Chrome 실행 실패**: `docker compose restart`로 컨테이너를 재시작하세요.
- **VNC 연결 실패**: 방화벽이나 보안 그룹에서 noVNC 포트의 인바운드 트래픽 허용 여부를 확인하세요.


## 추가 참고 사항

- 각 세션은 Docker 네임스페이스와 고유한 X11 소켓 볼륨을 통해 격리됩니다.
- `agent`와 `vnc` 컨테이너 간의 통신은 네트워크가 아닌 X11 UNIX 소켓을 통해서만 이루어집니다.
- 사용 사례에 맞게 agent 측 스크립트와 종속성을 자유롭게 추가하거나 수정할 수 있습니다.
