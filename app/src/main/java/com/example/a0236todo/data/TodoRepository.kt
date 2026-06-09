package com.example.a0236todo.data

/** DAO를 감싸 ViewModel에 단순한 인터페이스를 제공한다. */
class TodoRepository(
    private val dao: TodoDao,
    private val diaryDao: DiaryDao
) {

    // --- Todo ---
    fun observeByDate(date: String) = dao.observeByDate(date)

    fun observeById(id: Long) = dao.observeById(id)

    suspend fun getById(id: Long) = dao.getById(id)

    suspend fun insert(todo: TodoEntity) = dao.insert(todo)

    suspend fun update(todo: TodoEntity) = dao.update(todo)

    suspend fun delete(todo: TodoEntity) = dao.delete(todo)

    // --- Diary ---
    suspend fun getDiary(date: String) = diaryDao.getByDate(date)

    suspend fun saveDiary(date: String, content: String) {
        if (content.isBlank()) {
            diaryDao.getByDate(date)?.let { diaryDao.delete(it) }
        } else {
            diaryDao.upsert(DiaryEntity(date = date, content = content.trim()))
        }
    }
}
