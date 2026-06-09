package com.example.a0236todo.data

import androidx.room.Entity
import androidx.room.PrimaryKey

/** 하루에 한 개의 일기. date("yyyy-MM-dd")가 기본키. */
@Entity(tableName = "diaries")
data class DiaryEntity(
    @PrimaryKey val date: String,
    val content: String,
    val updatedAt: Long = System.currentTimeMillis()
)
