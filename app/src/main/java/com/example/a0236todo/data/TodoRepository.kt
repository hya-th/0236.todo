package com.example.a0236todo.data

import android.content.Context
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.map
import com.google.gson.Gson
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

/**
 * 할 일/일기 데이터를 **단일 JSON 파일(data.json)** 로 생성·관리하는 저장소.
 *
 * 구조:
 * ```
 * { "todos": [ ... ], "diaries": { "yyyy-MM-dd": "내용", ... } }
 * ```
 *
 * - 최초 실행 시 `assets/data.json` 을 초기 데이터로 읽어온다(seed).
 * - assets 는 읽기 전용이므로, 이후 모든 변경은 내부 저장소(filesDir)의 `data.json` 에 저장한다.
 */
class TodoRepository(private val context: Context) {

    private val gson = Gson()
    private val file = File(context.filesDir, FILE_NAME)

    private val items = mutableListOf<TodoEntity>()
    private val diaries = mutableMapOf<String, String>()
    private var nextId = 1L

    private val allTodos = MutableLiveData<List<TodoEntity>>(emptyList())

    /** data.json 의 직렬화 형태 */
    private data class AppData(
        val todos: List<TodoEntity>? = null,
        val diaries: Map<String, String>? = null
    )

    init {
        load()
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
        save()
        saved.id
    }

    suspend fun update(todo: TodoEntity) = withContext(Dispatchers.IO) {
        val index = items.indexOfFirst { it.id == todo.id }
        if (index >= 0) {
            items[index] = todo
            save()
        }
    }

    suspend fun delete(todo: TodoEntity) = withContext(Dispatchers.IO) {
        items.removeAll { it.id == todo.id }
        save()
    }

    suspend fun clearDate(date: String) = withContext(Dispatchers.IO) {
        items.removeAll { it.date == date }
        save()
    }

    // ---------------- 일기/회고 ----------------

    suspend fun getDiary(date: String): DiaryEntity? =
        diaries[date]?.let { DiaryEntity(date, it) }

    suspend fun saveDiary(date: String, content: String) = withContext(Dispatchers.IO) {
        if (content.isBlank()) diaries.remove(date) else diaries[date] = content.trim()
        save()
    }

    // ---------------- JSON 입출력 ----------------

    private fun load() {
        readJson()?.let { json ->
            runCatching {
                gson.fromJson(json, AppData::class.java)
            }.getOrNull()?.let { data ->
                items.addAll(data.todos ?: emptyList())
                diaries.putAll(data.diaries ?: emptyMap())
                nextId = (items.maxOfOrNull { it.id } ?: 0L) + 1
            }
        }
        allTodos.postValue(items.toList())
    }

    /** 내부 저장소 우선, 없으면 assets/data.json 을 초기값으로 읽는다. */
    private fun readJson(): String? = if (file.exists()) {
        runCatching { file.readText() }.getOrNull()
    } else {
        runCatching {
            context.assets.open(FILE_NAME).bufferedReader().use { it.readText() }
        }.getOrNull()
    }

    /** 현재 데이터를 내부 저장소 data.json 에 저장하고 LiveData 를 갱신한다. */
    private fun save() {
        runCatching {
            file.writeText(gson.toJson(AppData(items.toList(), diaries.toMap())))
        }
        allTodos.postValue(items.toList())
    }

    companion object {
        private const val FILE_NAME = "data.json"
    }
}
