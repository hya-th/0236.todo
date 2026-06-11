package com.example.a0236todo.ui.todo

import android.app.DatePickerDialog
import android.app.TimePickerDialog
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.Toast
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.a0236todo.R
import com.example.a0236todo.databinding.DialogAddTodoBinding
import com.example.a0236todo.databinding.DialogDiaryBinding
import com.example.a0236todo.databinding.FragmentTodoBinding
import com.example.a0236todo.util.DateUtils
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter
import java.util.Locale

class TodoFragment : Fragment() {

    private val dbDateFmt: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd")
    private val dbTimeFmt: DateTimeFormatter = DateTimeFormatter.ofPattern("HH:mm")
    private val uiDateFmt: DateTimeFormatter =
        DateTimeFormatter.ofPattern("M월 d일 (E)", Locale.KOREAN)
    private val uiTimeFmt: DateTimeFormatter =
        DateTimeFormatter.ofPattern("a h:mm", Locale.KOREAN)

    private var _binding: FragmentTodoBinding? = null
    private val binding get() = _binding!!

    private val viewModel: TodoViewModel by viewModels()

    private val adapter by lazy {
        TodoAdapter(
            onToggle = { viewModel.toggle(it) },
            onClick = { todo ->
                findNavController().navigate(
                    R.id.todoDetailFragment,
                    bundleOf("todoId" to todo.id)
                )
            }
        )
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentTodoBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        // 캘린더 등에서 특정 날짜로 진입한 경우
        arguments?.getString("dateKey")?.let { viewModel.setDate(it) }

        binding.rvTodos.layoutManager = LinearLayoutManager(requireContext())
        binding.rvTodos.adapter = adapter

        binding.btnBack.setOnClickListener { findNavController().navigate(R.id.homeFragment) }
        binding.btnPrev.setOnClickListener { viewModel.prevDay() }
        binding.btnNext.setOnClickListener { viewModel.nextDay() }
        binding.btnAdd.setOnClickListener { showAddDialog() }
        binding.diaryBar.setOnClickListener { showDiaryDialog() }
        binding.btnClear.setOnClickListener { showClearAllDialog() }

        viewModel.date.observe(viewLifecycleOwner) { key ->
            binding.tvSelectedDate.text = DateUtils.displayShort(key)
            // 지난 날짜에만 일기 쓰기 노출
            binding.diaryBar.visibility = if (DateUtils.isPast(key)) View.VISIBLE else View.GONE
        }
        viewModel.todos.observe(viewLifecycleOwner) { list ->
            adapter.submitList(list)
            binding.emptyView.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE

            val done = list.count { it.isDone }
            binding.tvProgress.text = "$done / ${list.size} 완료"
            binding.bowlView.setProgress(done, list.size)
        }
    }

    private fun showAddDialog() {
        val b = DialogAddTodoBinding.inflate(layoutInflater)

        // 시작/종료 날짜·시간 상태 (시작 = 현재 보고 있는 날짜, 종료 = +1시간)
        var startDate = LocalDate.parse(viewModel.date.value ?: DateUtils.todayKey(), dbDateFmt)
        var startTime = LocalTime.now().withMinute(0)
        var endDate = startDate
        var endTime = startTime.plusHours(1)
        var selectedColor = TodoColors.DEFAULT

        b.vColorDot.background = TodoColors.circle(selectedColor)
        b.vColorDot.setOnClickListener {
            showColorPicker(selectedColor) { picked ->
                selectedColor = picked
                b.vColorDot.background = TodoColors.circle(selectedColor)
            }
        }

        fun refresh() {
            b.tvStartDate.text = startDate.format(uiDateFmt)
            b.tvEndDate.text = endDate.format(uiDateFmt)
            val allDay = b.swAllDay.isChecked
            b.tvStartTime.visibility = if (allDay) View.GONE else View.VISIBLE
            b.tvEndTime.visibility = if (allDay) View.GONE else View.VISIBLE
            b.tvStartTime.text = startTime.format(uiTimeFmt)
            b.tvEndTime.text = endTime.format(uiTimeFmt)
        }
        refresh()

        b.swAllDay.setOnCheckedChangeListener { _, _ -> refresh() }

        b.startGroup.setOnClickListener {
            DatePickerDialog(requireContext(), { _, y, m, d ->
                startDate = LocalDate.of(y, m + 1, d)
                if (endDate.isBefore(startDate)) endDate = startDate
                TimePickerDialog(requireContext(), { _, h, min ->
                    startTime = LocalTime.of(h, min)
                    refresh()
                }, startTime.hour, startTime.minute, false).show()
                refresh()
            }, startDate.year, startDate.monthValue - 1, startDate.dayOfMonth).show()
        }
        b.endGroup.setOnClickListener {
            DatePickerDialog(requireContext(), { _, y, m, d ->
                endDate = LocalDate.of(y, m + 1, d)
                TimePickerDialog(requireContext(), { _, h, min ->
                    endTime = LocalTime.of(h, min)
                    refresh()
                }, endTime.hour, endTime.minute, false).show()
                refresh()
            }, endDate.year, endDate.monthValue - 1, endDate.dayOfMonth).show()
        }

        val dialog = MaterialAlertDialogBuilder(requireContext())
            .setView(b.root)
            .create()

        b.btnCancel.setOnClickListener { dialog.dismiss() }
        b.btnConfirm.setOnClickListener {
            val title = b.etTitle.text?.toString().orEmpty().trim()
            if (title.isEmpty()) {
                b.etTitle.error = getString(R.string.add_title_hint)
                return@setOnClickListener
            }
            val allDay = b.swAllDay.isChecked
            val startKey = startDate.format(dbDateFmt)
            viewModel.add(
                title = title,
                date = startKey,
                time = if (allDay) "" else startTime.format(dbTimeFmt),
                allDay = allDay,
                endDate = endDate.format(dbDateFmt),
                endTime = if (allDay) "" else endTime.format(dbTimeFmt),
                repeat = b.swRepeat.isChecked,
                color = selectedColor
            )
            viewModel.setDate(startKey) // 추가한 날짜로 이동해 바로 보이도록
            dialog.dismiss()
        }
        dialog.show()
    }

    private fun showColorPicker(current: String, onPick: (String) -> Unit) {
        val ctx = requireContext()
        val pad = dp(20)
        val row = LinearLayout(ctx).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(pad, pad, pad, pad)
        }
        val scroll = HorizontalScrollView(ctx).apply {
            isHorizontalScrollBarEnabled = false
            addView(row)
        }
        val dialog = MaterialAlertDialogBuilder(ctx)
            .setTitle("테마 색 선택")
            .setView(scroll)
            .create()

        val size = dp(38)
        TodoColors.PRESETS.forEach { hex ->
            val swatch = View(ctx).apply {
                layoutParams = LinearLayout.LayoutParams(size, size).apply { marginEnd = dp(8) }
                background = TodoColors.circle(hex, dp(if (hex == current) 4 else 2))
                setOnClickListener { onPick(hex); dialog.dismiss() }
            }
            row.addView(swatch)
        }
        dialog.show()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private fun showClearAllDialog() {
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.clear_all)
            .setMessage(R.string.clear_all_msg)
            .setPositiveButton(R.string.action_delete) { _, _ -> viewModel.clearAll() }
            .setNegativeButton(R.string.action_cancel, null)
            .show()
    }

    private fun showDiaryDialog() {
        val date = viewModel.date.value ?: return
        val dialogBinding = DialogDiaryBinding.inflate(layoutInflater)
        viewModel.loadDiary(date) { existing ->
            if (_binding == null) return@loadDiary
            dialogBinding.etDiary.setText(existing)
            MaterialAlertDialogBuilder(requireContext())
                .setTitle(DateUtils.displayShort(date))
                .setView(dialogBinding.root)
                .setPositiveButton(R.string.action_save) { _, _ ->
                    viewModel.saveDiary(date, dialogBinding.etDiary.text?.toString().orEmpty())
                    Toast.makeText(requireContext(), R.string.diary_saved, Toast.LENGTH_SHORT).show()
                }
                .setNegativeButton(R.string.action_cancel, null)
                .show()
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
