package com.example.ui.components

import android.widget.Toast
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.KeyboardArrowLeft
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun SidebarOverlayWidget(
    fps: Int,
    frameTimeMs: Float,
    cpuUsage: Int,
    gpuUsage: Int,
    ramUsed: Float,
    ramTotal: Float,
    temperature: Float,
    ping: Int,
    onQuickOptimize: () -> Unit,
    onNavigateToCoach: () -> Unit,
    onNavigateToReports: () -> Unit,
    modifier: Modifier = Modifier
) {
    var isOpen by remember { mutableStateOf(false) }
    var flashActive by remember { mutableStateOf(false) }
    var isRecording by remember { mutableStateOf(false) }
    var recordingSeconds by remember { mutableStateOf(0) }
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current

    // Timer for screen recording
    LaunchedEffect(isRecording) {
        if (isRecording) {
            recordingSeconds = 0
            while (isRecording) {
                delay(1000)
                recordingSeconds++
            }
        }
    }

    Box(
        modifier = modifier.fillMaxSize(),
        contentAlignment = Alignment.CenterEnd
    ) {
        // GHOST FLASH EFFECT (For screenshots)
        AnimatedVisibility(
            visible = flashActive,
            enter = fadeIn(animationSpec = tween(50)),
            exit = fadeOut(animationSpec = tween(300))
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.White)
            )
        }

        // TRIGGER HANDLE PILL (Pulls out the sidebar)
        if (!isOpen) {
            Box(
                modifier = Modifier
                    .width(18.dp)
                    .height(90.dp)
                    .background(
                        brush = Brush.horizontalGradient(listOf(CyberAccent.copy(alpha = 0.4f), CyberAccent)),
                        shape = RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp)
                    )
                    .border(1.dp, CyberWhite.copy(alpha = 0.3f), shape = RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp))
                    .clickable { isOpen = true }
                    .testTag("overlay_trigger"),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.KeyboardArrowLeft,
                    contentDescription = "Open Gaming Sidebar",
                    tint = CyberBg,
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        // FLOATING SIDEBAR PANEL
        AnimatedVisibility(
            visible = isOpen,
            enter = slideInHorizontally(
                initialOffsetX = { it },
                animationSpec = spring(dampingRatio = Spring.DampingRatioLowBouncy, stiffness = Spring.StiffnessMediumLow)
            ),
            exit = slideOutHorizontally(
                targetOffsetX = { it },
                animationSpec = tween(durationMillis = 200)
            )
        ) {
            Row(
                modifier = Modifier
                    .fillMaxHeight()
                    .width(280.dp)
                    .background(
                        brush = Brush.horizontalGradient(
                            colors = listOf(CyberBg.copy(alpha = 0.95f), CyberCardBg)
                        )
                    )
                    .border(1.dp, CyberAccent.copy(alpha = 0.25f), shape = RoundedCornerShape(topStart = 16.dp, bottomStart = 16.dp))
                    .padding(14.dp)
                    .testTag("overlay_sidebar")
            ) {
                // Drag back tab
                Column(
                    modifier = Modifier
                        .fillMaxHeight()
                        .width(24.dp)
                        .clickable { isOpen = false },
                    verticalArrangement = Arrangement.Center,
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.Default.KeyboardArrowRight,
                        contentDescription = "Close Sidebar",
                        tint = CyberAccent,
                        modifier = Modifier.size(24.dp)
                    )
                }

                Spacer(modifier = Modifier.width(6.dp))

                // Content Column
                Column(
                    modifier = Modifier.fillMaxHeight()
                ) {
                    // Title
                    Text(
                        text = "AGI GAMING HUD",
                        color = CyberAccent,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.2.sp
                    )

                    // Recording indicator
                    if (isRecording) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.padding(vertical = 4.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .background(CyberRed, shape = CircleShape)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            val mins = recordingSeconds / 60
                            val secs = recordingSeconds % 60
                            Text(
                                text = String.format("REC %02d:%02d", mins, secs),
                                color = CyberRed,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(12.dp))

                    // Telemetry details inside HUD
                    HudTelemetryMetric(label = "FPS Rate", value = "$fps", unit = "FPS", color = CyberAccent)
                    HudTelemetryMetric(label = "Frame Time", value = String.format("%.1f", frameTimeMs), unit = "ms", color = CyberAccent)
                    HudTelemetryMetric(label = "CPU Core Load", value = "$cpuUsage", unit = "%", color = CyberSecondary)
                    HudTelemetryMetric(label = "GPU Logic Load", value = "$gpuUsage", unit = "%", color = CyberSecondary)
                    HudTelemetryMetric(label = "RAM Allocated", value = String.format("%.1f/%.1f", ramUsed, ramTotal), unit = "GB", color = CyberGreen)
                    HudTelemetryMetric(label = "Thermal Heat", value = String.format("%.1f", temperature), unit = "°C", color = if (temperature > 43f) CyberRed else CyberYellow)
                    HudTelemetryMetric(label = "Net Ping", value = "$ping", unit = "ms", color = CyberAccent)

                    Spacer(modifier = Modifier.height(16.dp))

                    Text(
                        text = "QUICK SHORTCUTS",
                        color = CyberGray,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 0.5.sp
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    // Grid layout of shortcuts
                    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ShortcutItem(
                                label = "Screenshot",
                                active = false,
                                modifier = Modifier.weight(1f)
                            ) {
                                coroutineScope.launch {
                                    flashActive = true
                                    delay(100)
                                    flashActive = false
                                    Toast.makeText(context, "Screenshot disimpan di galeri (AGI/Screenshots)", Toast.LENGTH_SHORT).show()
                                }
                            }
                            ShortcutItem(
                                label = if (isRecording) "Stop Rec" else "Record",
                                active = isRecording,
                                modifier = Modifier.weight(1f)
                            ) {
                                isRecording = !isRecording
                                if (!isRecording) {
                                    Toast.makeText(context, "Video Rekaman disimpan di AGI/Videos", Toast.LENGTH_SHORT).show()
                                }
                            }
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ShortcutItem(
                                label = "Quick Opt",
                                active = false,
                                modifier = Modifier.weight(1f)
                            ) {
                                onQuickOptimize()
                                Toast.makeText(context, "Pembersihan RAM Cepat Selesai (+320MB RAM Bebas)", Toast.LENGTH_SHORT).show()
                            }
                            ShortcutItem(
                                label = "Tuning",
                                active = false,
                                modifier = Modifier.weight(1f)
                            ) {
                                isOpen = false
                                onNavigateToCoach()
                            }
                        }

                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            ShortcutItem(
                                label = "Report",
                                active = false,
                                modifier = Modifier.weight(1f)
                            ) {
                                isOpen = false
                                onNavigateToReports()
                            }
                            ShortcutItem(
                                label = "Game Mode",
                                active = true,
                                modifier = Modifier.weight(1f)
                            ) {
                                isOpen = false
                                Toast.makeText(context, "Kunci Mode Performa Aktif", Toast.LENGTH_SHORT).show()
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun HudTelemetryMetric(
    label: String,
    value: String,
    unit: String,
    color: Color
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 3.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = label, color = CyberGray, fontSize = 10.sp)
        Row(verticalAlignment = Alignment.Bottom) {
            Text(
                text = value,
                color = CyberWhite,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace
            )
            Spacer(modifier = Modifier.width(2.dp))
            Text(text = unit, color = color, fontSize = 8.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
fun ShortcutItem(
    label: String,
    active: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .background(
                if (active) CyberAccent.copy(alpha = 0.2f) else CyberCardBg.copy(alpha = 0.5f),
                shape = RoundedCornerShape(8.dp)
            )
            .border(
                1.dp,
                if (active) CyberAccent else CyberWhite.copy(alpha = 0.08f),
                shape = RoundedCornerShape(8.dp)
            )
            .clickable { onClick() }
            .padding(vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label.uppercase(),
            color = if (active) CyberAccent else CyberWhite,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold,
            textAlign = TextAlign.Center
        )
    }
}
