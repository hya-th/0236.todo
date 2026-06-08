# 0236.todo 🐱

26-1 앱 프로그래밍 기말 프로젝트 — 고양이 컨셉의 파스텔 감성 투두/플래너 앱

## 컨셉

`#F8FAF8` 배경의 부드러운 세이지·민트·피치 파스텔 톤, 고양이 마스코트를 사용한
귀여운 데일리 플래너입니다.

> **컨셉: 생산성은 냥이 돌보기 🐾**
> 할 일을 완료할 때마다 냥이의 밥그릇이 채워지고, 냥이가 더 행복해져요 😊

## 구현 현황

| 화면 | 상태 | 설명 |
|------|------|------|
| 홈 (Home) | ✅ | 인사말·오늘 진행률(밥그릇)·전체todo/월간/위클리 바로가기 |
| 데일리 플래너 (Todo) | ✅ | 날짜 이동, 할 일 추가·완료, 행 탭 → 상세 |
| 할 일 상세 (Detail) | ✅ | 시간·고양이 알림·우선순위·메모 편집/저장/삭제 |
| 캘린더 (Calendar) | ✅ | 월 달력 그리드, 날짜 탭 → 캘린더 상세 |
| 캘린더 상세 | ✅ | 해당 날짜 타임라인, 보상 카드 |
| 위클리 (Weekly) | ✅ | 이번 주 7일 목록, 급여 현황 |

### 필요한 이미지 리소스

아래 일러스트를 `app/src/main/res/drawable/` 에 추가해야 빌드됩니다 (소문자 PNG):

`cat_blue.png` · `cat_pink.png` · `cat_silhouette.png` · `cat_folder.png` · `cat_calendar.png`

## 기술 스택

- **언어**: Kotlin
- **UI**: XML + View, ViewBinding, Material 3
- **아키텍처**: Fragment + ViewModel + LiveData + Repository
- **네비게이션**: Navigation Component + BottomNavigationView
- **로컬 DB**: Room

## 프로젝트 구조

```
app/src/main/java/com/example/a0236todo/
├─ MainActivity.kt            # 하단 네비게이션 호스트
├─ TodoApplication.kt         # 전역 Repository 보관
├─ data/                      # Room (Entity / Dao / Database / Repository)
├─ util/DateUtils.kt          # 날짜 키 ↔ 표시 문자열 변환
└─ ui/
   ├─ home/                   # 홈 화면
   ├─ todo/                   # 데일리 플래너 (목록/추가/완료/삭제)
   └─ placeholder/            # 캘린더·위클리 (예정)
```

## 빌드 방법

1. Android Studio에서 이 폴더를 **Open**
2. Gradle Sync 완료 대기 (필요한 라이브러리 자동 다운로드)
3. 에뮬레이터 또는 기기에서 ▶ Run

- compileSdk 35 / minSdk 26 / targetSdk 35
- AGP 8.7.3 · Kotlin 2.0.21 · Gradle 8.14.3
