package com.example.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import kotlin.math.sin

@Composable
fun TelemetryHudGrid(
    fps: Int,
    cpuUsage: Int,
    gpuUsage: Int,
    ramUsed: Float,
    ramTotal: Float,
    temperature: Float,
    ping: Int,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier.fillMaxWidth()) {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            TelemetryMeterCard(
                label = "FRAME RATE",
                value = "$fps",
                unit = "FPS",
                progress = (fps / 120f).coerceIn(0f, 1f),
                accentColor = CyberAccent,
                modifier = Modifier.weight(1f),
                testTag = "hud_fps"
            )
            TelemetryMeterCard(
                label = "SUHU PERANGKAT",
                value = String.format("%.1f", temperature),
                unit = "°C",
                progress = ((temperature - 30f) / 20f).coerceIn(0f, 1f),
                accentColor = if (temperature > 43f) CyberRed else CyberYellow,
                modifier = Modifier.weight(1f),
                testTag = "hud_temp"
            )
        }
        Spacer(modifier = Modifier.height(10.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            TelemetryMeterCard(
                label = "BEBAN CPU",
                value = "$cpuUsage",
                unit = "%",
                progress = cpuUsage / 100f,
                accentColor = CyberSecondary,
                modifier = Modifier.weight(1f),
                testTag = "hud_cpu"
            )
            TelemetryMeterCard(
                label = "BEBAN GPU",
                value = "$gpuUsage",
                unit = "%",
                progress = gpuUsage / 100f,
                accentColor = CyberSecondary,
                modifier = Modifier.weight(1f),
                testTag = "hud_gpu"
            )
        }
        Spacer(modifier = Modifier.height(10.dp))
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            TelemetryMeterCard(
                label = "MEMORI RAM",
                value = String.format("%.1f", ramUsed),
                unit = "GB",
                progress = ramUsed / ramTotal,
                accentColor = CyberGreen,
                modifier = Modifier.weight(1f),
                testTag = "hud_ram"
            )
            TelemetryMeterCard(
                label = "PING JARINGAN",
                value = "$ping",
                unit = "ms",
                progress = (1f - (ping / 150f)).coerceIn(0f, 1f),
                accentColor = if (ping > 80) CyberRed else if (ping > 40) CyberYellow else CyberAccent,
                modifier = Modifier.weight(1f),
                testTag = "hud_ping"
            )
        }
    }
}

@Composable
fun TelemetryMeterCard(
    label: String,
    value: String,
    unit: String,
    progress: Float,
    accentColor: Color,
    modifier: Modifier = Modifier,
    testTag: String = ""
) {
    Box(
        modifier = modifier
            .background(CyberCardBg, shape = RoundedCornerShape(12.dp))
            .border(1.dp, CyberSecondary.copy(alpha = 0.15f), shape = RoundedCornerShape(12.dp))
            .padding(12.dp)
            .testTag(testTag)
    ) {
        Column {
            Text(
                text = label,
                color = CyberGray,
                fontSize = 10.sp,
                fontWeight = FontWeight.SemiBold,
                letterSpacing = 0.5.sp
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(verticalAlignment = Alignment.Bottom) {
                Text(
                    text = value,
                    color = CyberWhite,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
                Spacer(modifier = Modifier.width(4.dp))
                Text(
                    text = unit,
                    color = accentColor,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
            // Linear tech progress bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(4.dp)
                    .background(CyberWhite.copy(alpha = 0.08f), shape = RoundedCornerShape(2.dp))
            ) {
                val animatedWidth by animateFloatAsState(
                    targetValue = progress,
                    animationSpec = spring(stiffness = Spring.StiffnessLow),
                    label = "ProgressBarWidth"
                )
                Box(
                    modifier = Modifier
                        .fillMaxWidth(animatedWidth)
                        .fillMaxHeight()
                        .background(accentColor, shape = RoundedCornerShape(2.dp))
                )
            }
        }
    }
}

@Composable
fun TelemetryWaveChart(
    fpsHistory: List<Int>,
    tempHistory: List<Float>,
    pingHistory: List<Int>,
    modifier: Modifier = Modifier
) {
    var activeChartTab by remember { mutableStateOf(0) } // 0: FPS, 1: TEMP, 2: PING

    Column(
        modifier = modifier
            .fillMaxWidth()
            .background(CyberCardBg, shape = RoundedCornerShape(16.dp))
            .border(1.dp, CyberAccent.copy(alpha = 0.15f), shape = RoundedCornerShape(16.dp))
            .padding(16.dp)
    ) {
        // Tab Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "GRAFIK ANALISIS REAL-TIME",
                color = CyberWhite,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.8.sp
            )
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                ChartTabButton(text = "FPS", active = activeChartTab == 0) { activeChartTab = 0 }
                ChartTabButton(text = "TEMP", active = activeChartTab == 1) { activeChartTab = 1 }
                ChartTabButton(text = "PING", active = activeChartTab == 2) { activeChartTab = 2 }
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Render Wave Graph via Canvas
        val activePoints = when (activeChartTab) {
            0 -> fpsHistory.map { it.toFloat() }
            1 -> tempHistory.map { it }
            else -> pingHistory.map { it.toFloat() }
        }

        val minVal = activePoints.minOrNull() ?: 0f
        val maxVal = activePoints.maxOrNull() ?: 100f
        val range = if (maxVal == minVal) 1f else maxVal - minVal

        val accentColor = when (activeChartTab) {
            0 -> CyberAccent
            1 -> CyberYellow
            else -> CyberSecondary
        }

        Canvas(
            modifier = Modifier
                .fillMaxWidth()
                .height(110.dp)
                .testTag("telemetry_canvas")
        ) {
            val width = size.width
            val height = size.height
            val stepX = width / (activePoints.size - 1)

            val path = Path()
            val fillPath = Path()

            activePoints.forEachIndexed { idx, value ->
                // Normalize to canvas height
                val normY = height - ((value - minVal) / range) * (height * 0.75f) - (height * 0.1f)
                val x = idx * stepX

                if (idx == 0) {
                    path.moveTo(x, normY)
                    fillPath.moveTo(x, height)
                    fillPath.lineTo(x, normY)
                } else {
                    // Smooth quadratic Bezier points
                    val prevNormY = height - ((activePoints[idx - 1] - minVal) / range) * (height * 0.75f) - (height * 0.1f)
                    val prevX = (idx - 1) * stepX
                    val controlX = (prevX + x) / 2
                    path.quadraticTo(controlX, prevNormY, x, normY)
                    fillPath.quadraticTo(controlX, prevNormY, x, normY)
                }

                if (idx == activePoints.size - 1) {
                    fillPath.lineTo(x, height)
                    fillPath.close()
                }
            }

            // Draw shadow fill
            drawPath(
                path = fillPath,
                brush = Brush.verticalGradient(
                    colors = listOf(accentColor.copy(alpha = 0.25f), Color.Transparent)
                )
            )

            // Draw line
            drawPath(
                path = path,
                color = accentColor,
                style = Stroke(width = 2.dp.toPx())
            )

            // Draw current indicator dot
            if (activePoints.isNotEmpty()) {
                val lastIdx = activePoints.size - 1
                val lastVal = activePoints[lastIdx]
                val lastX = lastIdx * stepX
                val lastY = height - ((lastVal - minVal) / range) * (height * 0.75f) - (height * 0.1f)

                drawCircle(
                    color = CyberWhite,
                    radius = 4.dp.toPx(),
                    center = Offset(lastX, lastY)
                )
                drawCircle(
                    color = accentColor,
                    radius = 7.dp.toPx(),
                    center = Offset(lastX, lastY),
                    style = Stroke(width = 1.5.dp.toPx())
                )
            }
        }

        Spacer(modifier = Modifier.height(10.dp))

        // Display current value details under the graph
        val detailsText = when (activeChartTab) {
            0 -> "Frame rate rata-rata: ${String.format("%.1f", fpsHistory.average())} FPS | Stabilitas tinggi"
            1 -> "Suhu puncak: ${String.format("%.1f", tempHistory.maxOrNull() ?: 0f)}°C | Termal stabil"
            else -> "Ping rata-rata: ${String.format("%.1f", pingHistory.average())}ms | Latency rendah"
        }

        Text(
            text = detailsText,
            color = CyberGray,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
fun ChartTabButton(
    text: String,
    active: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .background(
                if (active) CyberAccent.copy(alpha = 0.15f) else Color.Transparent,
                shape = RoundedCornerShape(6.dp)
            )
            .border(
                1.dp,
                if (active) CyberAccent else CyberWhite.copy(alpha = 0.1f),
                shape = RoundedCornerShape(6.dp)
            )
            .clickable { onClick() }
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text = text,
            color = if (active) CyberAccent else CyberGray,
            fontSize = 9.sp,
            fontWeight = FontWeight.Bold
        )
    }
}
