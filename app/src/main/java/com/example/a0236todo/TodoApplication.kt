package com.example.a0236todo

import android.app.Application
import com.example.a0236todo.data.TodoRepository

/** 앱 전역에서 공유하는 Repository(JSON 파일 기반)를 보관한다. */
class TodoApplication : Application() {

    val repository: TodoRepository by lazy { TodoRepository(this) }
}
