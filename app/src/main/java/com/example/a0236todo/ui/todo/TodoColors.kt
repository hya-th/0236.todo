package com.example.a0236todo.ui.todo

import android.graphics.Color
import android.graphics.drawable.GradientDrawable

/** 할 일 테마 색 프리셋과 원형 드로어블 생성 도우미. */
object TodoColors {

    const val DEFAULT = "#D7C4F0"

    /** 색상 선택기에 노출할 파스텔 프리셋 */
    val PRESETS = listOf(
        "#F49AC2", // pink
        "#D7C4F0", // lavender
        "#BFE5F2", // baby blue
        "#B8E6D0", // mint
        "#FFD9B8", // peach
        "#FFE08A", // yellow
        "#F4789A"  // rose
    )

    private const val STROKE = "#E79BC3"

    /** hex 색의 원형 드로어블(테두리 포함)을 만든다. */
    fun circle(hex: String, strokeWidthPx: Int = 3): GradientDrawable {
        val fill = runCatching { Color.parseColor(hex) }.getOrDefault(Color.parseColor(DEFAULT))
        return GradientDrawable().apply {
            shape = GradientDrawable.OVAL
            setColor(fill)
            setStroke(strokeWidthPx, Color.parseColor(STROKE))
        }
    }
}
