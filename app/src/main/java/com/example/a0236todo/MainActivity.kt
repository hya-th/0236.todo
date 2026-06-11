package com.example.a0236todo

import android.graphics.Typeface
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.navigation.NavController
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.fragment.NavHostFragment
import androidx.navigation.navOptions
import com.example.a0236todo.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {

    private lateinit var binding: ActivityMainBinding

    private data class Tab(
        val cell: View,
        val box: View,
        val icon: ImageView,
        val label: TextView,
        val destId: Int
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        val navController = (supportFragmentManager
            .findFragmentById(R.id.nav_host_fragment) as NavHostFragment).navController

        val tabs = listOf(
            Tab(binding.navHome, binding.navHomeBox, binding.navHomeIcon, binding.navHomeLabel, R.id.homeFragment),
            Tab(binding.navTodo, binding.navTodoBox, binding.navTodoIcon, binding.navTodoLabel, R.id.todoFragment),
            Tab(binding.navCalendar, binding.navCalendarBox, binding.navCalendarIcon, binding.navCalendarLabel, R.id.calendarFragment),
            Tab(binding.navWeekly, binding.navWeeklyBox, binding.navWeeklyIcon, binding.navWeeklyLabel, R.id.weeklyFragment)
        )

        tabs.forEach { tab ->
            tab.cell.setOnClickListener {
                if (navController.currentDestination?.id != tab.destId) {
                    navController.navigate(tab.destId, null, navOptions {
                        launchSingleTop = true
                        restoreState = true
                        popUpTo(navController.graph.findStartDestination().id) {
                            saveState = true
                        }
                    })
                }
            }
        }

        navController.addOnDestinationChangedListener { _, destination, _ ->
            val activeTabId = activeTabFor(destination.id)
            tabs.forEach { setSelected(it, it.destId == activeTabId) }
        }
    }

    /** 상세/하위 화면은 자신이 속한 탭을 활성으로 표시한다. */
    private fun activeTabFor(destinationId: Int): Int = when (destinationId) {
        R.id.todoFragment, R.id.todoDetailFragment -> R.id.todoFragment
        R.id.calendarFragment, R.id.calendarDetailFragment -> R.id.calendarFragment
        R.id.weeklyFragment -> R.id.weeklyFragment
        else -> R.id.homeFragment // homeFragment, catStatusFragment
    }

    private fun setSelected(tab: Tab, selected: Boolean) {
        tab.box.setBackgroundResource(if (selected) R.drawable.bg_nav_active else 0)
        val color = ContextCompat.getColor(
            this, if (selected) R.color.pink_dark else R.color.text_secondary
        )
        tab.icon.setColorFilter(color)
        tab.label.setTextColor(color)
        tab.label.setTypeface(null, if (selected) Typeface.BOLD else Typeface.NORMAL)
    }
}
