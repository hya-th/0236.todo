package com.example.a0236todo.ui.todo

import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentTodoDetailBinding
import com.example.a0236todo.databinding.ItemMemoEntryBinding
import com.example.a0236todo.util.DateUtils

class TodoDetailFragment : Fragment() {

    private var _binding: FragmentTodoDetailBinding? = null
    private val binding get() = _binding!!

    private val viewModel: TodoDetailViewModel by viewModels()

    private var selectedPriority = 1
    private var loaded = false
    private val memos = mutableListOf<String>()

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

        // 메모 입력 시에만 + 버튼 활성화
        binding.etMemo.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, st: Int, c: Int, a: Int) {}
            override fun onTextChanged(s: CharSequence?, st: Int, b: Int, c: Int) {}
            override fun afterTextChanged(s: Editable?) {
                setAddEnabled(!s.isNullOrBlank())
            }
        })
        setAddEnabled(false)
        binding.btnAddMemo.setOnClickListener { addMemo() }

        binding.btnDelete.setOnClickListener {
            viewModel.delete { findNavController().popBackStack() }
        }
        binding.btnDone.setOnClickListener {
            // 입력창에 남은 텍스트도 마지막 메모로 포함
            val pending = binding.etMemo.text.toString().trim()
            if (pending.isNotEmpty()) memos.add(pending)
            viewModel.save(
                time = binding.etTime.text.toString(),
                priority = selectedPriority,
                reminder = binding.swReminder.isChecked,
                memo = memos.joinToString("\n"),
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
            selectPriority(todo.priority)

            memos.clear()
            memos.addAll(todo.memo.split("\n").map { it.trim() }.filter { it.isNotEmpty() })
            renderMemoList()
        }
    }

    private fun setAddEnabled(enabled: Boolean) {
        binding.btnAddMemo.isEnabled = enabled
        binding.btnAddMemo.alpha = if (enabled) 1f else 0.35f
    }

    private fun addMemo() {
        val text = binding.etMemo.text.toString().trim()
        if (text.isEmpty()) return
        memos.add(text)
        binding.etMemo.setText("")
        renderMemoList()
    }

    private fun renderMemoList() {
        binding.memoListContainer.removeAllViews()
        binding.memoListSection.visibility = if (memos.isEmpty()) View.GONE else View.VISIBLE
        memos.forEachIndexed { index, memo ->
            val row = ItemMemoEntryBinding.inflate(
                layoutInflater, binding.memoListContainer, false
            )
            row.tvIndex.text = (index + 1).toString()
            row.tvMemoText.text = memo
            row.btnDeleteMemo.setOnClickListener {
                memos.removeAt(index)
                renderMemoList()
            }
            binding.memoListContainer.addView(row.root)
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
