package com.example.a0236todo.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query

@Dao
interface DiaryDao {

    @Query("SELECT * FROM diaries WHERE date = :date")
    suspend fun getByDate(date: String): DiaryEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(diary: DiaryEntity)

    @Delete
    suspend fun delete(diary: DiaryEntity)
}
