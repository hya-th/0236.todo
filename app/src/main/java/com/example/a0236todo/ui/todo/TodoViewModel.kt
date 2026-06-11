package com.example.a0236todo.ui.todo

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.switchMap
import androidx.lifecycle.viewModelScope
import com.example.a0236todo.TodoApplication
import com.example.a0236todo.data.TodoEntity
import com.example.a0236todo.util.DateUtils
import kotlinx.coroutines.launch

class TodoViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = (app as TodoApplication).repository

    private val _date = MutableLiveData(DateUtils.todayKey())
    val date: LiveData<String> = _date

    /** 선택된 날짜가 바뀌면 자동으로 해당 날짜의 목록을 다시 관찰한다. */
    val todos: LiveData<List<TodoEntity>> =
        _date.switchMap { repository.observeByDate(it) }

    fun setDate(key: String) {
        if (_date.value != key) _date.value = key
    }

    fun prevDay() {
        _date.value = DateUtils.shift(_date.value!!, -1)
    }

    fun nextDay() {
        _date.value = DateUtils.shift(_date.value!!, 1)
    }

    fun add(title: String) {
        val text = title.trim()
        if (text.isEmpty()) return
        viewModelScope.launch {
            repository.insert(TodoEntity(title = text, date = _date.value!!))
        }
    }

    fun toggle(todo: TodoEntity) = viewModelScope.launch {
        repository.update(todo.copy(isDone = !todo.isDone))
    }

    fun delete(todo: TodoEntity) = viewModelScope.launch {
        repository.delete(todo)
    }

    /** 현재 날짜의 모든 할 일 삭제 (전체 비우기) */
    fun clearAll() = viewModelScope.launch {
        repository.clearDate(_date.value!!)
    }

    /** 해당 날짜의 일기 내용을 콜백으로 전달 (없으면 빈 문자열). */
    fun loadDiary(date: String, onResult: (String) -> Unit) = viewModelScope.launch {
        onResult(repository.getDiary(date)?.content ?: "")
    }

    fun saveDiary(date: String, content: String) = viewModelScope.launch {
        repository.saveDiary(date, content)
    }
}
