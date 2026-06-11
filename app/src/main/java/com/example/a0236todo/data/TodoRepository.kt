package com.example.a0236todo.data

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.map
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * 할 일/일기 데이터를 **JSON 파일**로 생성·관리하는 저장소.
 *
 * - todos.json : 할 일 목록(List<TodoEntity>)
 * - diaries.json : 일기/회고(Map<date, content>)
 *
 * 메모리 상의 목록을 LiveData로 노출하고, 변경 시마다 JSON 파일에 직렬화해 저장한다.
 */
class TodoRepository(context: Context) {

    private val gson = Gson()
    private val todoFile = File(context.filesDir, "todos.json")
    private val diaryFile = File(context.filesDir, "diaries.json")

    private val items = mutableListOf<TodoEntity>()
    private val diaries = mutableMapOf<String, String>()
    private var nextId = 1L

    /** 전체 할 일(스냅샷)을 담는 LiveData. 날짜별 조회는 여기서 파생한다. */
    private val allTodos = MutableLiveData<List<TodoEntity>>(emptyList())

    init {
        loadTodos()
        loadDiaries()
    }

    // ---------------- 조회 ----------------

    fun observeByDate(date: String): LiveData<List<TodoEntity>> =
        allTodos.map { list ->
            list.filter { it.date == date }
                .sortedWith(compareBy({ it.isDone }, { it.time }, { it.createdAt }))
        }

    fun observeById(id: Long): LiveData<TodoEntity?> =
        allTodos.map { list -> list.find { it.id == id } }

    suspend fun getById(id: Long): TodoEntity? = items.find { it.id == id }

    // ---------------- 생성/수정/삭제 ----------------

    suspend fun insert(todo: TodoEntity): Long = withContext(Dispatchers.IO) {
        val saved = todo.copy(id = nextId++)
        items.add(saved)
        saveTodos()
        saved.id
    }

    suspend fun update(todo: TodoEntity) = withContext(Dispatchers.IO) {
        val index = items.indexOfFirst { it.id == todo.id }
        if (index >= 0) {
            items[index] = todo
            saveTodos()
        }
    }

    suspend fun delete(todo: TodoEntity) = withContext(Dispatchers.IO) {
        items.removeAll { it.id == todo.id }
        saveTodos()
    }

    suspend fun clearDate(date: String) = withContext(Dispatchers.IO) {
        items.removeAll { it.date == date }
        saveTodos()
    }

    // ---------------- 일기/회고 ----------------

    suspend fun getDiary(date: String): DiaryEntity? =
        diaries[date]?.let { DiaryEntity(date, it) }

    suspend fun saveDiary(date: String, content: String) = withContext(Dispatchers.IO) {
        if (content.isBlank()) diaries.remove(date) else diaries[date] = content.trim()
        diaryFile.writeText(gson.toJson(diaries))
    }

    // ---------------- JSON 입출력 ----------------

    private fun loadTodos() {
        if (todoFile.exists()) {
            runCatching {
                val type = object : TypeToken<List<TodoEntity>>() {}.type
                val loaded: List<TodoEntity> = gson.fromJson(todoFile.readText(), type) ?: emptyList()
                items.addAll(loaded)
                nextId = (items.maxOfOrNull { it.id } ?: 0L) + 1
            }
        }
        allTodos.postValue(items.toList())
    }

    private fun loadDiaries() {
        if (diaryFile.exists()) {
            runCatching {
                val type = object : TypeToken<Map<String, String>>() {}.type
                val loaded: Map<String, String> = gson.fromJson(diaryFile.readText(), type) ?: emptyMap()
                diaries.putAll(loaded)
            }
        }
    }

    /** 메모리 목록을 JSON으로 저장하고 LiveData를 갱신한다. */
    private fun saveTodos() {
        todoFile.writeText(gson.toJson(items))
        allTodos.postValue(items.toList())
    }
}
