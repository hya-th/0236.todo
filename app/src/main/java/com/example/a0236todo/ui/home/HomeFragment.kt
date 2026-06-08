package com.example.a0236todo.ui.home

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentHomeBinding

class HomeFragment : Fragment() {

    private var _binding: FragmentHomeBinding? = null
    private val binding get() = _binding!!

    private val viewModel: HomeViewModel by viewModels()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentHomeBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        binding.cardAllTodo.setOnClickListener { findNavController().navigate(R.id.todoFragment) }
        binding.cardMonthly.setOnClickListener { findNavController().navigate(R.id.calendarFragment) }
        binding.cardWeekly.setOnClickListener { findNavController().navigate(R.id.weeklyFragment) }

        viewModel.todos.observe(viewLifecycleOwner) { list ->
            val done = list.count { it.isDone }
            val total = list.size
            binding.tvProgressCount.text = "오늘 할 일 $done / $total 완료"
            binding.progressBar.max = if (total == 0) 1 else total
            binding.progressBar.progress = done
            binding.tvProgressCaption.text = if (total == 0) {
                getString(R.string.home_progress_empty)
            } else {
                getString(R.string.home_progress_caption)
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
