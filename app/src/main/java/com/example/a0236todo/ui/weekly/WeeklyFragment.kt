package com.example.a0236todo.ui.weekly

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentWeeklyBinding
import com.example.a0236todo.databinding.ItemWeekDayBinding
import com.example.a0236todo.ui.todo.TodoViewModel
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale

class WeeklyFragment : Fragment() {

    private var _binding: FragmentWeeklyBinding? = null
    private val binding get() = _binding!!

    private val viewModel: TodoViewModel by viewModels()

    private val keyFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private lateinit var reflectionKey: String

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentWeeklyBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.btnBack.setOnClickListener { findNavController().navigate(R.id.homeFragment) }

        // 일~토 기준 한 주
        val sunday = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.SUNDAY))
        val today = LocalDate.now()

        for (i in 0..6) {
            val date = sunday.plusDays(i.toLong())
            val rowBinding = ItemWeekDayBinding.inflate(layoutInflater, binding.weekContainer, false)

            rowBinding.tvDayName.text =
                date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN)
            rowBinding.tvDayNum.text = date.dayOfMonth.toString()
            rowBinding.tvDaySummary.text =
                if (date == today) "오늘 · 탭하여 보기" else "탭하여 할 일 보기"

            rowBinding.root.setOnClickListener {
                findNavController().navigate(
                    R.id.todoFragment,
                    bundleOf("dateKey" to date.format(keyFormat))
                )
            }
            binding.weekContainer.addView(rowBinding.root)
        }

        // 한 주 회고 (이번 주 일요일 날짜를 키로 저장)
        reflectionKey = "wk-" + sunday.format(keyFormat)
        viewModel.loadDiary(reflectionKey) { saved ->
            if (_binding != null) binding.etReflection.setText(saved)
        }
        binding.btnSaveReflection.setOnClickListener {
            viewModel.saveDiary(reflectionKey, binding.etReflection.text?.toString().orEmpty())
            Toast.makeText(requireContext(), R.string.weekly_saved, Toast.LENGTH_SHORT).show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
