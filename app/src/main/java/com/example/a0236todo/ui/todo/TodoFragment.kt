package com.example.a0236todo.ui.todo

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.a0236todo.R
import com.example.a0236todo.databinding.DialogAddTodoBinding
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
            onDelete = { viewModel.delete(it) }
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
        binding.rvTodos.layoutManager = LinearLayoutManager(requireContext())
        binding.rvTodos.adapter = adapter

        binding.btnPrev.setOnClickListener { viewModel.prevDay() }
        binding.btnNext.setOnClickListener { viewModel.nextDay() }
        binding.fabAdd.setOnClickListener { showAddDialog() }

        viewModel.date.observe(viewLifecycleOwner) { key ->
            binding.tvSelectedDate.text = DateUtils.display(key)
        }
        viewModel.todos.observe(viewLifecycleOwner) { list ->
            adapter.submitList(list)
            binding.emptyView.visibility = if (list.isEmpty()) View.VISIBLE else View.GONE
        }
    }

    private fun showAddDialog() {
        val dialogBinding = DialogAddTodoBinding.inflate(layoutInflater)
        MaterialAlertDialogBuilder(requireContext())
            .setTitle(R.string.todo_add)
            .setView(dialogBinding.root)
            .setPositiveButton(R.string.action_add) { _, _ ->
                viewModel.add(dialogBinding.etTitle.text?.toString().orEmpty())
            }
            .setNegativeButton(R.string.action_cancel, null)
            .show()
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
