package com.example.a0236todo.ui.todo

import android.graphics.Paint
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.a0236todo.data.TodoEntity
import com.example.a0236todo.databinding.ItemTodoBinding

class TodoAdapter(
    private val onToggle: (TodoEntity) -> Unit,
    private val onClick: (TodoEntity) -> Unit = {}
) : ListAdapter<TodoEntity, TodoAdapter.VH>(DIFF) {

    inner class VH(private val binding: ItemTodoBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(item: TodoEntity) {
            binding.tvTitle.text = item.title
            binding.cbDone.buttonTintList = null
            binding.cbDone.isChecked = item.isDone

            binding.tvTime.text = item.time
            binding.tvTime.visibility = if (item.time.isBlank()) View.GONE else View.VISIBLE

            // 완료된 항목은 취소선 + 흐리게 표시
            binding.tvTitle.paintFlags = if (item.isDone) {
                binding.tvTitle.paintFlags or Paint.STRIKE_THRU_TEXT_FLAG
            } else {
                binding.tvTitle.paintFlags and Paint.STRIKE_THRU_TEXT_FLAG.inv()
            }
            binding.tvTitle.alpha = if (item.isDone) 0.5f else 1f

            binding.cbDone.setOnClickListener { onToggle(item) }
            binding.root.setOnClickListener { onClick(item) }
        }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val binding = ItemTodoBinding.inflate(
            LayoutInflater.from(parent.context), parent, false
        )
        return VH(binding)
    }

    override fun onBindViewHolder(holder: VH, position: Int) =
        holder.bind(getItem(position))

    companion object {
        private val DIFF = object : DiffUtil.ItemCallback<TodoEntity>() {
            override fun areItemsTheSame(oldItem: TodoEntity, newItem: TodoEntity) =
                oldItem.id == newItem.id

            override fun areContentsTheSame(oldItem: TodoEntity, newItem: TodoEntity) =
                oldItem == newItem
        }
    }
}
