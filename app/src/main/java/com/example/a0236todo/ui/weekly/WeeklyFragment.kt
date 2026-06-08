package com.example.a0236todo.ui.weekly

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentWeeklyBinding
import com.example.a0236todo.databinding.ItemWeekDayBinding
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale

class WeeklyFragment : Fragment() {

    private var _binding: FragmentWeeklyBinding? = null
    private val binding get() = _binding!!

    private val keyFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentWeeklyBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val monday = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        val today = LocalDate.now()

        for (i in 0..6) {
            val date = monday.plusDays(i.toLong())
            val rowBinding = ItemWeekDayBinding.inflate(layoutInflater, binding.weekContainer, false)

            rowBinding.tvDayName.text =
                date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN)
            rowBinding.tvDayNum.text = date.dayOfMonth.toString()
            rowBinding.tvDaySummary.text =
                if (date == today) "오늘 · 탭하여 보기" else "탭하여 할 일 보기"

            rowBinding.root.setOnClickListener {
                findNavController().navigate(
                    R.id.calendarDetailFragment,
                    bundleOf("dateKey" to date.format(keyFormat))
                )
            }
            binding.weekContainer.addView(rowBinding.root)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
