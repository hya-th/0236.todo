package com.example.a0236todo.data

import androidx.room.Entity
import androidx.room.PrimaryKey

/**
 * 할 일 한 건을 나타내는 Room 엔티티.
 *
 * @property date "yyyy-MM-dd" 형식의 날짜 키. 날짜별로 할 일을 조회할 때 사용한다.
 */
@Entity(tableName = "todos")
data class TodoEntity(
    @PrimaryKey(autoGenerate = true) val id: Long = 0,
    val title: String,
    val isDone: Boolean = false,
    val date: String,
    val memo: String = "",
    val createdAt: Long = System.currentTimeMillis()
)
