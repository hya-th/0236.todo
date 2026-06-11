package com.example.a0236todo.data

import androidx.lifecycle.LiveData
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.Query
import androidx.room.Update

@Dao
interface TodoDao {

    /** 특정 날짜의 할 일을 (미완료 우선, 시간/생성순)으로 관찰한다. */
    @Query("SELECT * FROM todos WHERE date = :date ORDER BY isDone ASC, time ASC, createdAt ASC")
    fun observeByDate(date: String): LiveData<List<TodoEntity>>

    @Query("SELECT * FROM todos WHERE id = :id")
    fun observeById(id: Long): LiveData<TodoEntity?>

    @Query("SELECT * FROM todos WHERE id = :id")
    suspend fun getById(id: Long): TodoEntity?

    @Insert
    suspend fun insert(todo: TodoEntity): Long

    @Update
    suspend fun update(todo: TodoEntity)

    @Delete
    suspend fun delete(todo: TodoEntity)

    @Query("DELETE FROM todos WHERE date = :date")
    suspend fun deleteByDate(date: String)
}
