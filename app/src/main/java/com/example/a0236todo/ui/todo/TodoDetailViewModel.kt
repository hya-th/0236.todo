package com.example.a0236todo.ui.todo

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.switchMap
import androidx.lifecycle.viewModelScope
import com.example.a0236todo.TodoApplication
import com.example.a0236todo.data.TodoEntity
import kotlinx.coroutines.launch

class TodoDetailViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = (app as TodoApplication).repository

    private val _id = MutableLiveData<Long>()
    val todo: LiveData<TodoEntity?> = _id.switchMap { repository.observeById(it) }

    fun load(id: Long) {
        if (_id.value != id) _id.value = id
    }

    fun save(time: String, priority: Int, reminder: Boolean, memo: String, title: String) {
        val current = todo.value ?: return
        viewModelScope.launch {
            repository.update(
                current.copy(
                    title = title.ifBlank { current.title },
                    time = time.trim(),
                    priority = priority,
                    reminder = reminder,
                    memo = memo.trim()
                )
            )
        }
    }

    fun delete(onDeleted: () -> Unit) {
        val current = todo.value ?: return onDeleted()
        viewModelScope.launch {
            repository.delete(current)
            onDeleted()
        }
    }
}
