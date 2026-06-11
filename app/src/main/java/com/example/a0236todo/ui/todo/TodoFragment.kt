package com.example.a0236todo.ui.todo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
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

class TodoFragment : Fragment() {

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
        val dialogBinding = DialogAddTodoBinding.inflate(layoutInflater)
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.action_add)
            .setView(dialogBinding.root)
            .setPositiveButton(R.string.action_add) { _, _ ->
                viewModel.add(dialogBinding.etTitle.text?.toString().orEmpty())
            }
            .setNegativeButton(R.string.action_cancel, null)
            .show()
    }

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
