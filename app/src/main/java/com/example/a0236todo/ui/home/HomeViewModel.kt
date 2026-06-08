package com.example.a0236todo.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.example.a0236todo.TodoApplication
import com.example.a0236todo.data.TodoEntity
import com.example.a0236todo.util.DateUtils
import kotlinx.coroutines.launch

class HomeViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = (app as TodoApplication).repository

    val today: String = DateUtils.todayKey()
    val todos = repository.observeByDate(today)

    fun toggle(todo: TodoEntity) = viewModelScope.launch {
        repository.update(todo.copy(isDone = !todo.isDone))
    }
}
