package com.example.a0236todo.ui.todo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentTodoDetailBinding
import com.example.a0236todo.util.DateUtils

class TodoDetailFragment : Fragment() {

    private var _binding: FragmentTodoDetailBinding? = null
    private val binding get() = _binding!!

    private val viewModel: TodoDetailViewModel by viewModels()

    private var selectedPriority = 1
    private var loaded = false

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentTodoDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val todoId = arguments?.getLong("todoId") ?: -1L
        viewModel.load(todoId)

        binding.btnBack.setOnClickListener { findNavController().popBackStack() }

        binding.chipLow.setOnClickListener { selectPriority(0) }
        binding.chipNormal.setOnClickListener { selectPriority(1) }
        binding.chipHigh.setOnClickListener { selectPriority(2) }

        binding.btnDelete.setOnClickListener {
            viewModel.delete { findNavController().popBackStack() }
        }
        binding.btnDone.setOnClickListener {
            viewModel.save(
                time = binding.etTime.text.toString(),
                priority = selectedPriority,
                reminder = binding.swReminder.isChecked,
                memo = binding.etMemo.text.toString(),
                title = binding.etTitle.text.toString()
            )
            findNavController().popBackStack()
        }

        viewModel.todo.observe(viewLifecycleOwner) { todo ->
            // 최초 1회만 입력 필드에 채워, 사용자의 편집을 덮어쓰지 않는다.
            if (todo == null || loaded) return@observe
            loaded = true
            binding.etTitle.setText(todo.title)
            binding.tvDate.text = DateUtils.displayShort(todo.date)
            binding.etTime.setText(todo.time)
            binding.swReminder.isChecked = todo.reminder
            binding.etMemo.setText(todo.memo)
            selectPriority(todo.priority)
        }
    }

    private fun selectPriority(priority: Int) {
        selectedPriority = priority
        bindChip(binding.chipLow, priority == 0)
        bindChip(binding.chipNormal, priority == 1)
        bindChip(binding.chipHigh, priority == 2)
    }

    private fun bindChip(chip: TextView, selected: Boolean) {
        chip.setBackgroundResource(
            if (selected) R.drawable.bg_chip_selected else R.drawable.bg_chip
        )
        chip.setTextColor(
            resources.getColor(
                if (selected) R.color.white else R.color.text_secondary,
                null
            )
        )
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
