package com.example.a0236todo.data

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 할 일 한 건을 나타내는 Room 엔티티.
 *
 * @property date "yyyy-MM-dd" 형식의 날짜 키
 * @property time "HH:mm" 형식의 시간(선택)
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
    val priority: Int = 1,
    val reminder: Boolean = false,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
