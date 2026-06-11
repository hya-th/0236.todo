package com.example.a0236todo.ui.todo

import com.example.a0236todo.R

/** 투두 완료율(0~1)에 따라 표시할 밥그릇 이미지를 고른다. (비어 있음 → 가득) */
object BowlAssets {

    private val levels = intArrayOf(
        R.drawable.bowl_0, // 빈 그릇
        R.drawable.bowl_1, // 조금
        R.drawable.bowl_2, // 절반
        R.drawable.bowl_3, // 거의 가득
        R.drawable.bowl_4  // 가득(수북)
    )

    fun resFor(done: Int, total: Int): Int {
        if (total <= 0) return levels[0]
        val ratio = done.toFloat() / total
        val index = Math.round(ratio * (levels.size - 1)).coerceIn(0, levels.size - 1)
        return levels[index]
    }
}
