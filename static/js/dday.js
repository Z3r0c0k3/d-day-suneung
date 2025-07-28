function getCsatDate(year) {
    const november = new Date(year, 10, 1);
    const firstDay = november.getDay(); // 0(일) ~ 6(토)
    
    // 셋째 주 목요일(4) 찾기
    let thirdThursday = 1 + (4 - firstDay + 7) % 7 + 14;
    
    return new Date(year, 10, thirdThursday, 8, 40, 0); // 1교시 시작 시간
}

function getMockExamDate(year, month) {
    // 교육청 발표에 따라 실제 날짜는 달라질 수 있습니다.
    // 여기서는 예시로 월의 첫째 주 목요일로 가정합니다.
    const date = new Date(year, month - 1, 1);
    const firstDay = date.getDay();
    const firstThursday = 1 + (4 - firstDay + 7) % 7;
    return new Date(year, month - 1, firstThursday, 8, 40, 0);
}

// 월, 일(0-indexed month)
const mockExamDates = {
    'mock-exam-03': new Date(2025, 2, 27), 
    'mock-exam-06': new Date(2025, 5, 4),
    'mock-exam-09': new Date(2025, 8, 3),
};

function updateCounter(elementId, targetDate) {
    const counter = document.getElementById(elementId);
    if (!counter) return;

    const finishedQuotes = [
        '포기하지 말아요.',
        '열심히 했어요.',
        '정말 수고 많았어요.',
        '결과가 어떻든, 당신은 최고예요.',
        '새로운 시작을 응원해요.'
    ];

    const intervalId = setInterval(update, 47);

    function update() {
        const now = new Date();
        const difference = targetDate - now;

        if (difference < 0) {
            const randomQuote = finishedQuotes[Math.floor(Math.random() * finishedQuotes.length)];
            counter.innerHTML = randomQuote;
            counter.style.fontSize = '1.2rem'; // 문구에 어울리게 폰트 크기 조정
            counter.style.letterSpacing = 'normal'; // 자간 조정
            clearInterval(intervalId); // 카운터 업데이트 중지
            return;
        }

        const days = Math.floor(difference / (1000 * 60 * 60 * 24));
        const hours = Math.floor((difference % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
        const minutes = Math.floor((difference % (1000 * 60 * 60)) / (1000 * 60));
        const seconds = Math.floor((difference % (1000 * 60)) / 1000);
        const milliseconds = difference % 1000;

        counter.innerHTML = `D-${String(days).padStart(3, '0')} | ${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(milliseconds).padStart(3, '0')}`;
    }

    update();
}


function initializeApp() {
    // --- PWA Install Button ---
    console.log("Initializing PWA install button logic...");
    const installBtn = document.getElementById('install-btn');
    let deferredPrompt;

    window.addEventListener('beforeinstallprompt', (e) => {
        console.log('beforeinstallprompt event fired.');
        // Prevent the mini-infobar from appearing on mobile
        e.preventDefault();
        // Stash the event so it can be triggered later.
        deferredPrompt = e;
        // Update UI notify the user they can install the PWA
        installBtn.classList.remove('hidden');
        console.log('Install button should now be visible.');
    });

    installBtn.addEventListener('click', async () => {
        // Hide the app provided install promotion
        installBtn.classList.add('hidden');
        // Show the install prompt
        deferredPrompt.prompt();
        // Wait for the user to respond to the prompt
        const { outcome } = await deferredPrompt.userChoice;
        console.log(`User response to the install prompt: ${outcome}`);
        // We've used the prompt, and can't use it again, throw it away
        deferredPrompt = null;
    });

    window.addEventListener('appinstalled', (evt) => {
        // Log install to analytics
        console.log('INSTALL: Success');
    });

    // --- Typing Animation ---
    const quotes = [
        "자, 오늘도 열심히 해봐요.",
        "오늘도 파이팅.",
        "꿈을 향해서 한 발자국씩.",
        "아니야, 할 수 있어요.",
        "봐요, 꼭 해낼거라고 말했죠.",
        "남은 시간까지 계속 달려봐요.",
        "오늘도 꿈과 한 발자국 가까워졌어요.",
        "이제 잠깐 쉬어가요. 잘 달려왔어요."
    ];

    function typeQuote(element) {
        if (!element) return;
        
        if (element.typingTimeout) {
            clearTimeout(element.typingTimeout);
        }

        const quote = quotes[Math.floor(Math.random() * quotes.length)];
        let i = 0;
        element.textContent = '';
        
        function typing() {
            if (i < quote.length) {
                element.textContent += quote.charAt(i);
                i++;
                element.typingTimeout = setTimeout(typing, 100);
            }
        }
        typing();
    }

    document.querySelectorAll('.motivational-quote').forEach(el => {
        typeQuote(el);
    });

    // --- Dynamic Year Setup ---
    const now = new Date();
    const currentYear = now.getFullYear();

    // 수능 카운터 설정: 항상 현재 연도를 기준으로 계산
    document.querySelectorAll('[data-csat-counter]').forEach(elem => {
        const yearOffset = parseInt(elem.dataset.csatCounter, 10);
        const targetYear = currentYear + yearOffset;
        const csatDate = getCsatDate(targetYear);
        elem.querySelector('h2').textContent = `${targetYear + 1}학년도 대학수학능력시험까지`;
        const counterId = `csat-${yearOffset}`;
        elem.querySelector('div').id = counterId;
        updateCounter(counterId, csatDate);
    });

    // 모의고사 카운터 설정: 항상 현재 연도를 기준으로 계산
    document.querySelectorAll('[data-mock-counter]').forEach(elem => {
        const targetMonth = parseInt(elem.dataset.mockCounter, 10);
        const mockDate = getMockExamDate(currentYear, targetMonth);
        elem.querySelector('h2').textContent = `${currentYear}년 ${targetMonth}월 모의고사까지`;
        const counterId = `mock-exam-${targetMonth}`;
        elem.querySelector('div').id = counterId;
        updateCounter(counterId, mockDate);
    });

    // --- 가로 스크롤 및 네비게이션 ---
    const pageContainer = document.querySelector('.page-container');
    const prevBtn = document.getElementById('prev-btn');
    const nextBtn = document.getElementById('next-btn');
    const dots = document.querySelectorAll('.dot');
    const totalPages = 3;
    let currentPage = 0;

    function updateIndicator() {
        dots.forEach((dot, index) => {
            dot.classList.toggle('active', index === currentPage);
        });
    }

    function goToPage(pageIndex) {
        if (pageIndex < 0 || pageIndex >= totalPages) return;
        pageContainer.style.transform = `translateX(-${pageIndex * 100}vw)`;
        currentPage = pageIndex;
        updateIndicator();

        // Trigger typing animation for the current page
        const activePage = document.querySelectorAll('.page')[currentPage];
        if (activePage) {
            const quoteElement = activePage.querySelector('.motivational-quote');
            typeQuote(quoteElement);
        }
    }

    prevBtn.addEventListener('click', () => goToPage(currentPage - 1));
    nextBtn.addEventListener('click', () => goToPage(currentPage + 1));

    // 터치 스와이프
    let touchstartX = 0;
    let touchendX = 0;

    pageContainer.addEventListener('touchstart', e => {
        touchstartX = e.changedTouches[0].screenX;
    });

    pageContainer.addEventListener('touchend', e => {
        touchendX = e.changedTouches[0].screenX;
        handleSwipe();
    });

    function handleSwipe() {
        if (touchendX < touchstartX) {
            goToPage(currentPage + 1); // Swipe left
        }
        if (touchendX > touchstartX) {
            goToPage(currentPage - 1); // Swipe right
        }
    }

    // --- 타이머 기능 ---
    const timerDisplay = document.querySelector('.timer-display');
    const startPauseBtn = document.getElementById('start-pause-btn');
    const resetBtn = document.getElementById('reset-btn');
    const selectSubjectBtn = document.getElementById('select-subject-btn');
    const subjectList = document.querySelector('.subject-list');

    let timerInterval;
    let endTime;
    let remainingTime = 0; // in ms
    let isRunning = false;

    function formatTime(ms) {
        if (ms < 0) ms = 0;
        const totalSeconds = Math.floor(ms / 1000);
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        const milliseconds = ms % 1000;
        return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(milliseconds).padStart(3, '0')}`;
    }

    selectSubjectBtn.addEventListener('click', () => {
        subjectList.classList.toggle('hidden');
    });

    subjectList.addEventListener('click', e => {
        if (e.target.tagName === 'LI') {
            remainingTime = parseInt(e.target.dataset.time, 10) * 1000;
            resetTimer();
            subjectList.classList.add('hidden');
            document.querySelector('#timer-page p').textContent = e.target.textContent.split(' - ')[0];
        }
    });

    function timerTick() {
        const newRemaining = endTime - Date.now();
        remainingTime = newRemaining;
        if (remainingTime <= 0) {
            pauseTimer();
            remainingTime = 0;
        }
        timerDisplay.textContent = formatTime(remainingTime);
    }

    function startTimer() {
        if (remainingTime <= 0 || isRunning) return;
        isRunning = true;
        startPauseBtn.textContent = '일시정지';
        endTime = Date.now() + remainingTime;
        timerInterval = setInterval(timerTick, 47);
    }

    function pauseTimer() {
        isRunning = false;
        startPauseBtn.textContent = '시작';
        clearInterval(timerInterval);
    }
    
    function resetTimer() {
        pauseTimer();
        timerDisplay.textContent = formatTime(remainingTime);
    }

    startPauseBtn.addEventListener('click', () => {
        if (isRunning) {
            pauseTimer();
        } else {
            startTimer();
        }
    });

    resetBtn.addEventListener('click', () => {
        // Find selected subject's original time and reset to it
        const selectedSubjectText = document.querySelector('#timer-page p').textContent;
        const subjectItems = Array.from(subjectList.querySelectorAll('li'));
        const selectedItem = subjectItems.find(item => item.textContent.startsWith(selectedSubjectText));
        if (selectedItem) {
            remainingTime = parseInt(selectedItem.dataset.time, 10) * 1000;
        }
        resetTimer();
    });
    
    // Initial setup
    goToPage(0); // Start on the first page and trigger its animation
}

window.onload = () => {
    const loadingScreen = document.getElementById('loading-screen');
    setTimeout(() => {
        loadingScreen.style.opacity = '0';
        setTimeout(() => {
            loadingScreen.style.display = 'none';
            initializeApp(); // Initialize app after loading screen is hidden
        }, 500);
    }, 2000);
}; 