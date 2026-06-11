package com.example.a0236todo.ui.todo

import android.graphics.Paint
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView
import com.example.a0236todo.data.TodoEntity
import com.example.a0236todo.databinding.ItemMemoLineBinding
import com.example.a0236todo.databinding.ItemTodoBinding

class TodoAdapter(
    private val onToggle: (TodoEntity) -> Unit,
    private val onClick: (TodoEntity) -> Unit = {}
) : ListAdapter<TodoEntity, TodoAdapter.VH>(DIFF) {

    /** 메모 드롭다운이 펼쳐진 할 일 id 모음 */
    private val expandedIds = mutableSetOf<Long>()

    inner class VH(private val binding: ItemTodoBinding) :
        RecyclerView.ViewHolder(binding.root) {

        fun bind(item: TodoEntity) {
            binding.tvTitle.text = item.title
            binding.cbDone.buttonTintList = null
            binding.cbDone.isChecked = item.isDone

            binding.tvTime.text = item.time
            binding.tvTime.visibility = if (item.time.isBlank()) View.GONE else View.VISIBLE

            binding.vColorDot.background = TodoColors.circle(item.color)

            // 완료된 항목은 취소선 + 흐리게 표시
            binding.tvTitle.paintFlags = if (item.isDone) {
                binding.tvTitle.paintFlags or Paint.STRIKE_THRU_TEXT_FLAG
            } else {
                binding.tvTitle.paintFlags and Paint.STRIKE_THRU_TEXT_FLAG.inv()
            }
            binding.tvTitle.alpha = if (item.isDone) 0.5f else 1f

            // 메모 드롭다운
            val hasMemo = item.memo.isNotBlank()
            val expanded = hasMemo && item.id in expandedIds
            binding.btnExpand.visibility = if (hasMemo) View.VISIBLE else View.GONE
            binding.btnExpand.setImageResource(
                if (expanded) com.example.a0236todo.R.drawable.ic_chevron_up
                else com.example.a0236todo.R.drawable.ic_chevron_down
            )
            bindMemoLines(item, expanded)

            binding.cbDone.setOnClickListener { onToggle(item) }
            binding.cardRow.setOnClickListener { onClick(item) }
            binding.btnExpand.setOnClickListener {
                if (item.id in expandedIds) expandedIds.remove(item.id)
                else expandedIds.add(item.id)
                val pos = adapterPosition
                if (pos != RecyclerView.NO_POSITION) notifyItemChanged(pos)
            }
        }

        private fun bindMemoLines(item: TodoEntity, expanded: Boolean) {
            binding.memoContainer.removeAllViews()
            if (!expanded) {
                binding.memoContainer.visibility = View.GONE
                return
            }
            binding.memoContainer.visibility = View.VISIBLE
            val inflater = LayoutInflater.from(binding.root.context)
            item.memo.split("\n")
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .forEach { line ->
                    val lineBinding = ItemMemoLineBinding.inflate(
                        inflater, binding.memoContainer, false
                    )
                    lineBinding.tvMemoLine.text = line
                    binding.memoContainer.addView(lineBinding.root)
                }
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
