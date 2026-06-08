# 0236.todo 🐱

26-1 앱 프로그래밍 기말 프로젝트 — 고양이 컨셉의 파스텔 감성 투두/플래너 앱

## 컨셉

`#F8FAF8` 배경의 부드러운 세이지·민트·피치 파스텔 톤, 고양이 마스코트를 사용한
귀여운 데일리 플래너입니다.

## 구현 현황

| 화면 | 상태 | 설명 |
|------|------|------|
| 홈 (Home) | ✅ 완료 | 오늘 날짜·진행률·오늘의 할 일 미리보기 |
| 투두 / 데일리 플래너 | ✅ 완료 | 날짜 이동, 할 일 추가·완료·삭제 (Room 저장) |
| 캘린더 | 🚧 자리만 | 추후 구현 |
| 위클리 | 🚧 자리만 | 추후 구현 |

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
