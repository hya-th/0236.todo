package com.example.a0236todo.ui.calendar

import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.GridLayout
import android.widget.TextView
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentCalendarBinding
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.DateTimeFormatter

class CalendarFragment : Fragment() {

    private var _binding: FragmentCalendarBinding? = null
    private val binding get() = _binding!!

    private var month: YearMonth = YearMonth.now()
    private val keyFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCalendarBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.btnPrevMonth.setOnClickListener { month = month.minusMonths(1); render() }
        binding.btnNextMonth.setOnClickListener { month = month.plusMonths(1); render() }
        render()
    }

    private fun render() {
        binding.tvMonth.text = "${month.year}년 ${month.monthValue}월"
        binding.gridDays.removeAllViews()

        // 그 달 1일의 요일 (일요일=0 기준 빈 칸 수)
        val firstDayOfWeek = month.atDay(1).dayOfWeek.value % 7 // MONDAY=1..SUNDAY=7 → SUN=0
        repeat(firstDayOfWeek) { binding.gridDays.addView(emptyCell()) }

        val today = LocalDate.now()
        for (day in 1..month.lengthOfMonth()) {
            val date = month.atDay(day)
            binding.gridDays.addView(dayCell(day, date == today, date))
        }
    }

    private fun emptyCell(): View = TextView(requireContext()).apply {
        layoutParams = cellParams()
    }

    private fun dayCell(day: Int, isToday: Boolean, date: LocalDate): TextView =
        TextView(requireContext()).apply {
            layoutParams = cellParams()
            text = day.toString()
            gravity = Gravity.CENTER
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 14f)
            if (isToday) {
                setBackgroundResource(R.drawable.bg_chip_selected)
                setTextColor(resources.getColor(R.color.white, null))
            } else {
                setTextColor(resources.getColor(R.color.text_primary, null))
            }
            setOnClickListener {
                findNavController().navigate(
                    R.id.calendarDetailFragment,
                    bundleOf("dateKey" to date.format(keyFormat))
                )
            }
        }

    private fun cellParams(): GridLayout.LayoutParams =
        GridLayout.LayoutParams().apply {
            width = 0
            height = dp(44)
            columnSpec = GridLayout.spec(GridLayout.UNDEFINED, 1f)
            setMargins(dp(2), dp(2), dp(2), dp(2))
        }

    private fun dp(value: Int): Int =
        (value * resources.displayMetrics.density).toInt()

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
