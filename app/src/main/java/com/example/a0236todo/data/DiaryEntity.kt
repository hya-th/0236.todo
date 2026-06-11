package com.example.a0236todo.data

/** 하루(또는 한 주)에 한 개의 일기/회고. JSON으로 저장. date가 키. */
data class DiaryEntity(
    val date: String,
    val content: String,
    val updatedAt: Long = System.currentTimeMillis()
)
