package com.example.a0236todo.ui.cat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentCatStatusBinding
import com.example.a0236todo.databinding.ItemDayChipBinding
import com.example.a0236todo.ui.todo.TodoViewModel
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.TextStyle
import java.time.temporal.TemporalAdjusters
import java.util.Locale

class CatStatusFragment : Fragment() {

    private var _binding: FragmentCatStatusBinding? = null
    private val binding get() = _binding!!

    private val viewModel: TodoViewModel by viewModels()

    private val keyFormat: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val dayChips = mutableListOf<Pair<LocalDate, ItemDayChipBinding>>()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentCatStatusBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.btnBack.setOnClickListener { findNavController().popBackStack() }

        buildDayStrip()
        selectDate(LocalDate.now())

        viewModel.todos.observe(viewLifecycleOwner) { list ->
            val done = list.count { it.isDone }
            val total = list.size
            val percent = if (total > 0) done * 100 / total else 0

            binding.ring.setProgressCompat(percent, true)
            binding.tvPercent.text = "$percent%"
            binding.tvStatDone.text = "$done / $total"
            binding.tvStatPercent.text = "$percent%"
            binding.tvStatRemain.text = "${total - done}개"
        }
    }

    private fun buildDayStrip() {
        val monday = LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY))
        for (i in 0..6) {
            val date = monday.plusDays(i.toLong())
            val chip = ItemDayChipBinding.inflate(layoutInflater, binding.dayStrip, false)
            chip.tvDow.text = date.dayOfWeek.getDisplayName(TextStyle.SHORT, Locale.KOREAN)
            chip.tvDom.text = date.dayOfMonth.toString()
            chip.root.setOnClickListener { selectDate(date) }
            binding.dayStrip.addView(chip.root)
            dayChips.add(date to chip)
        }
    }

    private fun selectDate(date: LocalDate) {
        viewModel.setDate(date.format(keyFormat))

        val white = resources.getColor(R.color.white, null)
        val textPrimary = resources.getColor(R.color.text_primary, null)
        val textSecondary = resources.getColor(R.color.text_secondary, null)

        dayChips.forEach { (d, chip) ->
            val selected = d == date
            chip.root.setBackgroundResource(
                if (selected) R.drawable.bg_day_selected else R.drawable.bg_day
            )
            chip.tvDow.setTextColor(if (selected) white else textSecondary)
            chip.tvDom.setTextColor(if (selected) white else textPrimary)
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
