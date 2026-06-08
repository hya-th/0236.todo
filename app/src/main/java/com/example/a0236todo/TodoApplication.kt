package com.example.a0236todo

import android.app.Application
import com.example.a0236todo.data.AppDatabase
import com.example.a0236todo.data.TodoRepository

/** 앱 전역에서 공유하는 Repository를 보관한다. */
class TodoApplication : Application() {

    val repository: TodoRepository by lazy {
        TodoRepository(AppDatabase.getInstance(this).todoDao())
    }
}
