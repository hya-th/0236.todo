package com.example.a0236todo.ui.home

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import com.example.a0236todo.TodoApplication
import com.example.a0236todo.util.DateUtils

/** 홈 화면용 ViewModel. 오늘 날짜의 할 일 목록을 관찰해 진행률 계산에 사용한다. */
class HomeViewModel(app: Application) : AndroidViewModel(app) {

    private val repository = (app as TodoApplication).repository

    val today: String = DateUtils.todayKey()
    val todos = repository.observeByDate(today)
}
