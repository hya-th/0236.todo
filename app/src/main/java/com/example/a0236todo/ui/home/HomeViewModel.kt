package com.example.a0236todo.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.example.a0236todo.TodoApplication
import com.example.a0236todo.util.DateUtils

class HomeViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = (app as TodoApplication).repository

    val today: String = DateUtils.todayKey()
    val todos = repository.observeByDate(today)
}
