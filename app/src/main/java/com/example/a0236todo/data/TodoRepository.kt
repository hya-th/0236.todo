package com.example.a0236todo.data

/** DAO를 감싸 ViewModel에 단순한 인터페이스를 제공한다. */
class TodoRepository(private val dao: TodoDao) {

    fun observeByDate(date: String) = dao.observeByDate(date)

    fun observeById(id: Long) = dao.observeById(id)

    suspend fun getById(id: Long) = dao.getById(id)

    suspend fun insert(todo: TodoEntity) = dao.insert(todo)

    suspend fun update(todo: TodoEntity) = dao.update(todo)

    suspend fun delete(todo: TodoEntity) = dao.delete(todo)
}
