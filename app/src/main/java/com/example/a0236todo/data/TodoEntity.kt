package com.example.a0236todo.data

/**
 * 할 일 한 건. JSON 파일로 저장/관리되는 순수 데이터 모델.
 *
 * @property date 시작 날짜 "yyyy-MM-dd"
 * @property time 시작 시간 "HH:mm" (하루 종일이면 빈 값)
 * @property allDay 하루 종일 여부
 * @property endDate 종료 날짜 "yyyy-MM-dd"
 * @property endTime 종료 시간 "HH:mm"
 * @property repeat 반복 여부
 * @property color 테마 색 (#RRGGBB)
 * @property priority 0=낮음, 1=보통, 2=높음
 * @property reminder 고양이 알림 사용 여부
 * @property memo 메모 (줄바꿈으로 여러 개)
 */
data class TodoEntity(
    val id: Long = 0,
    val title: String,
    val isDone: Boolean = false,
    val date: String,
    val time: String = "",
    val allDay: Boolean = false,
    val endDate: String = "",
    val endTime: String = "",
    val repeat: Boolean = false,
    val color: String = "#D7C4F0",
    val priority: Int = 1,
    val reminder: Boolean = false,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
