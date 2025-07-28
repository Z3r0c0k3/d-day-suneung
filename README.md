# 수능/모의고사 D-DAY & 타이머

수능 및 주요 모의고사 D-day 카운터와 학습 시간을 측정할 수 있는 타이머 기능을 제공하는 PWA(Progressive Web App)입니다.

![Screenshot](https://i.imgur.com/UFd6b2l.png)

## ✨ 주요 기능

- **D-day 카운터**:
  - 수능 및 3/6/9월 모의고사 D-day를 실시간으로 보여줍니다.
  - 밀리초 단위까지 정확하게 남은 시간을 표시합니다.
  - 매년 날짜가 자동으로 업데이트됩니다.
  - 시험 종료 후에는 격려 메시지를 보여줍니다.
- **학습 타이머**:
  - 국어, 수학, 영어 등 과목별 시험 시간에 맞춰 타이머를 설정할 수 있습니다.
  - 시작, 일시정지, 초기화 기능으로 학습 시간을 관리할 수 있습니다.
- **가로 스크롤 인터페이스**:
  - 모바일 환경에서는 스와이프로, 태블릿/PC에서는 버튼으로 페이지를 전환할 수 있습니다.
  - 수능, 모의고사, 타이머 페이지로 구성되어 있습니다.
- **동기부여 메시지**:
  - 페이지에 접속하거나 전환할 때마다 새로운 응원 메시지가 타이핑 애니메이션과 함께 나타납니다.
- **PWA 지원**:
  - 웹 앱을 스마트폰 홈 화면에 추가하여 네이티브 앱처럼 사용할 수 있습니다.
  - 오프라인 상태에서도 기본적인 기능이 동작합니다.

## 🛠 기술 스택

- **Backend**: Django, Gunicorn
- **Frontend**: HTML5, CSS3, JavaScript (ES6+)
- **Infra**: Nginx, Systemd
- **ETC**: PWA (Progressive Web App)

## ⚙️ 로컬 개발 환경 설정

1.  **저장소 복제**:

    ```bash
    git clone https://github.com/Z3r0c0k3/d-day-suneung.git
    cd d-day-suneung
    ```

2.  **가상 환경 생성 및 활성화**:

    ```bash
    python3 -m venv venv
    source venv/bin/activate
    ```

3.  **의존성 라이브러리 설치**:

    ```bash
    pip install -r requirements.txt
    ```

4.  **환경 변수 설정**:
    `.env.example` 파일을 복사하여 `.env` 파일을 생성하고, 필요에 따라 내용을 수정합니다.

    ```bash
    cp .env.example .env
    ```

5.  **데이터베이스 마이그레이션**:

    ```bash
    python manage.py migrate
    ```

6.  **개발 서버 실행**:
    ```bash
    python manage.py runserver
    ```
    이제 웹 브라우저에서 `http://127.0.0.1:8000`으로 접속하여 확인할 수 있습니다.

## 🚀 Ubuntu 22.04 프로덕션 배포

프로젝트에 포함된 `deploy.sh` 스크립트를 사용하여 Ubuntu 22.04 환경에 자동으로 배포할 수 있습니다.

1.  **서버에 프로젝트 업로드**:
    Git을 사용하거나 직접 파일을 서버에 업로드합니다.

2.  **스크립트 실행 권한 부여**:

    ```bash
    chmod +x deploy.sh
    ```

3.  **배포 스크립트 실행**:
    `sudo` 권한으로 스크립트를 실행합니다. 스크립트가 Nginx, Gunicorn 설치 및 설정을 모두 자동으로 처리합니다.
    ```bash
    sudo ./deploy.sh
    ```
4.  **Nginx 설정 확인**:
    배포 후 `/etc/nginx/sites-available/suneung_dday` 파일의 `server_name`을 실제 서버의 도메인이나 IP 주소로 변경하는 것을 권장합니다.

---

이 프로젝트가 수험생 여러분의 꿈을 향한 여정에 작은 도움이 되기를 바랍니다.
