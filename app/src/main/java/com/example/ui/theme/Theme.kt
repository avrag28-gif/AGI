package com.example.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val CyberColorScheme = darkColorScheme(
    primary = CyberAccent,
    secondary = CyberSecondary,
    tertiary = CyberGreen,
    background = CyberBg,
    surface = CyberCardBg,
    onPrimary = CyberBg,
    onSecondary = CyberWhite,
    onBackground = CyberWhite,
    onSurface = CyberWhite
)

@Composable
fun MyApplicationTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = CyberColorScheme,
        typography = Typography,
        content = content
    )
}
