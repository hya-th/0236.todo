package com.example.a0236todo.ui.placeholder

import android.os.Bundle
import android.view.View
import androidx.fragment.app.Fragment
import com.example.a0236todo.R
import com.example.a0236todo.databinding.FragmentPlaceholderBinding

/** 위클리 플래너 화면 (추후 구현 예정). */
class WeeklyFragment : Fragment(R.layout.fragment_placeholder) {
    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        FragmentPlaceholderBinding.bind(view).tvPlaceholderTitle.setText(R.string.nav_weekly)
    }
}
