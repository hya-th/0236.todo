package com.example.a0236todo.ui.home

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.a0236todo.databinding.FragmentHomeBinding
import com.example.a0236todo.ui.todo.TodoAdapter
import com.example.a0236todo.util.DateUtils

class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!

    private val viewModel: HomeViewModel by viewModels()

    private val adapter by lazy {
        TodoAdapter(
            onToggle = { viewModel.toggle(it) },
            onDelete = { /* 홈 미리보기에서는 삭제하지 않음 */ }
        )
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.tvDate.text = DateUtils.display(viewModel.today)
        binding.rvHomePreview.layoutManager = LinearLayoutManager(requireContext())
        binding.rvHomePreview.adapter = adapter

        viewModel.todos.observe(viewLifecycleOwner) { list ->
            adapter.submitList(list)

            val done = list.count { it.isDone }
            val total = list.size
            binding.tvProgressCount.text = "$done / $total 완료"
            binding.progressBar.max = if (total == 0) 1 else total
            binding.progressBar.progress = done

            val isEmpty = list.isEmpty()
            binding.tvHomeEmpty.visibility = if (isEmpty) View.VISIBLE else View.GONE
            binding.rvHomePreview.visibility = if (isEmpty) View.GONE else View.VISIBLE
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
