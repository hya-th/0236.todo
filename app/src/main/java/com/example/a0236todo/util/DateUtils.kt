package com.example.a0236todo.util

import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.Locale

/** DB 저장용 키("yyyy-MM-dd")와 화면 표시용 문자열을 변환하는 유틸리티. */
object DateUtils {

    private val keyFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val displayFormat: DateTimeFormatter =
        DateTimeFormatter.ofPattern("yyyy년 M월 d일 (E)", Locale.KOREAN)

    fun todayKey(): String = LocalDate.now().format(keyFormat)

    fun display(key: String): String =
        LocalDate.parse(key, keyFormat).format(displayFormat)

    fun shift(key: String, days: Long): String =
        LocalDate.parse(key, keyFormat).plusDays(days).format(keyFormat)
}
