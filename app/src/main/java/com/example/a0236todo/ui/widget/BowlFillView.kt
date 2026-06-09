package com.example.a0236todo.ui.widget

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import android.view.animation.DecelerateInterpolator
import androidx.core.content.ContextCompat
import com.example.a0236todo.R

/**
 * 할 일 완료율(0~1)에 따라 사료가 차오르는 고양이 밥그릇 뷰.
 * [setProgress] 호출 시 현재 양에서 목표 양까지 부드럽게 애니메이션한다.
 */
class BowlFillView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    private var currentLevel = 0f
    private var animator: ValueAnimator? = null

    private val bodyPath = Path()
    private val rimRect = RectF()

    private val interiorPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = ContextCompat.getColor(context, R.color.white)
    }
    private val foodPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = ContextCompat.getColor(context, R.color.peach)
    }
    private val foodTopPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.FILL
        color = ContextCompat.getColor(context, R.color.yellow)
    }
    private val outlinePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        color = ContextCompat.getColor(context, R.color.pink_dark)
        strokeWidth = dp(2.5f)
        strokeJoin = Paint.Join.ROUND
        strokeCap = Paint.Cap.ROUND
    }

    /** done/total 로 목표 채움 비율을 정해 애니메이션한다. */
    fun setProgress(done: Int, total: Int, animate: Boolean = true) {
        val target = if (total <= 0) 0f else (done.toFloat() / total).coerceIn(0f, 1f)
        setLevel(target, animate)
    }

    fun setLevel(target: Float, animate: Boolean = true) {
        animator?.cancel()
        if (!animate) {
            currentLevel = target
            invalidate()
            return
        }
        animator = ValueAnimator.ofFloat(currentLevel, target).apply {
            duration = 650
            interpolator = DecelerateInterpolator()
            addUpdateListener {
                currentLevel = it.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        val w = width.toFloat()
        val h = height.toFloat()
        val inset = dp(2f)

        val topY = h * 0.34f
        val botY = h * 0.86f
        val left = w * 0.12f + inset
        val right = w * 0.88f - inset
        val inLeft = w * 0.30f
        val inRight = w * 0.70f

        // 밥그릇 몸통(아래가 둥근 사다리꼴)
        bodyPath.reset()
        bodyPath.moveTo(left, topY)
        bodyPath.lineTo(right, topY)
        bodyPath.lineTo(inRight, botY)
        bodyPath.quadTo(w / 2f, h * 0.97f, inLeft, botY)
        bodyPath.close()

        // 1) 빈 그릇 내부(흰색)
        canvas.drawPath(bodyPath, interiorPaint)

        // 2) 사료 채우기 (아래에서 위로)
        if (currentLevel > 0f) {
            val foodTopY = botY - (botY - topY) * currentLevel
            canvas.save()
            canvas.clipPath(bodyPath)
            canvas.drawRect(0f, foodTopY, w, h, foodPaint)
            // 사료 표면 하이라이트
            canvas.drawRect(0f, foodTopY, w, foodTopY + dp(3f), foodTopPaint)
            canvas.restore()
        }

        // 3) 그릇 외곽선
        canvas.drawPath(bodyPath, outlinePaint)

        // 4) 그릇 입구(테두리 타원)
        rimRect.set(left, topY - h * 0.10f, right, topY + h * 0.10f)
        canvas.drawOval(rimRect, outlinePaint)
    }

    private fun dp(value: Float): Float = value * resources.displayMetrics.density

    override fun onDetachedFromWindow() {
        animator?.cancel()
        super.onDetachedFromWindow()
    }
}
