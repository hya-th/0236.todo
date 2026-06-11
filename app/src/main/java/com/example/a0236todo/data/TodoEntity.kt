package com.example.a0236todo.data

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 할 일 한 건을 나타내는 Room 엔티티.
 *
 * @property date 시작 날짜 "yyyy-MM-dd"
 * @property time 시작 시간 "HH:mm" (하루 종일이면 빈 값)
 * @property allDay 하루 종일 여부
 * @property endDate 종료 날짜 "yyyy-MM-dd"
 * @property endTime 종료 시간 "HH:mm"
 * @property repeat 반복 여부
 * @property priority 0=낮음, 1=보통, 2=높음
 * @property reminder 고양이 알림 사용 여부
 */
@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val isDone: Boolean = false,
    val date: String,
    val time: String = "",
    val allDay: Boolean = false,
    val endDate: String = "",
    val endTime: String = "",
    val repeat: Boolean = false,
    val priority: Int = 1,
    val reminder: Boolean = false,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
