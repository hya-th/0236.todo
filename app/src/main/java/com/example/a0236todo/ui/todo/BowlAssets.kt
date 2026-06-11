package com.example.a0236todo.ui.todo

import android.content.Context
import com.example.a0236todo.R

/**
 * 투두 완료율(0~1)에 따라 표시할 밥그릇 이미지를 고른다. (비어 있음 → 가득)
 *
 * bowl_0 ~ bowl_4 PNG를 drawable에 넣으면 자동 사용되고,
 * 아직 없으면 기본 아이콘(ic_bowl)으로 대체해 빌드/실행이 막히지 않는다.
 */
object BowlAssets {

    private const val LEVELS = 5

    fun resFor(context: Context, done: Int, total: Int): Int {
        val index = if (total <= 0) {
            0
        } else {
            Math.round(done.toFloat() / total * (LEVELS - 1)).coerceIn(0, LEVELS - 1)
        }
        val id = context.resources.getIdentifier(
            "bowl_$index", "drawable", context.packageName
        )
        return if (id != 0) id else R.drawable.ic_bowl
    }
}
