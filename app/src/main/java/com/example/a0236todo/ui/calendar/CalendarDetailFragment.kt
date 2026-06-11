package com.example.a0236todo.ui.calendar

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.core.os.bundleOf
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.findNavController
import androidx.recyclerview.widget.LinearLayoutManager
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentCalendarDetailBinding
import com.example.a0236todo.ui.todo.TodoAdapter
import com.example.a0236todo.ui.todo.TodoViewModel
import com.example.a0236todo.util.DateUtils

/**
 * 캘린더 상세 화면. 전달받은 날짜(dateKey)의 할 일을 타임라인으로 보여주고,
 * 진행률/하루 보상 카드와 일기 버튼을 제공한다. (투두와 동일한 [TodoViewModel] 재사용)
 */
class CalendarDetailFragment : Fragment() {

    private var _binding: FragmentCalendarDetailBinding? = null
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
        _binding = FragmentCalendarDetailBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        val dateKey = arguments?.getString("dateKey") ?: DateUtils.todayKey()
        viewModel.setDate(dateKey)

        binding.tvDate.text = DateUtils.display(dateKey)
        binding.btnBack.setOnClickListener { findNavController().popBackStack() }

        binding.rvTimeline.layoutManager = LinearLayoutManager(requireContext())
        binding.rvTimeline.adapter = adapter

        viewModel.todos.observe(viewLifecycleOwner) { list ->
            adapter.submitList(list)
            val done = list.count { it.isDone }
            binding.tvProgress.text = "$done / ${list.size} 완료"
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
