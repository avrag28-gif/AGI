package com.example.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*

@Composable
fun CyberGaugesRow(
    performanceScore: Int,
    networkScore: Int,
    thermalScore: Int,
    batteryScore: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        CyberGaugeCard(
            label = "PERFORMANCE",
            score = performanceScore,
            accentColor = CyberAccent,
            testTag = "performance_gauge"
        )
        CyberGaugeCard(
            label = "NETWORK",
            score = networkScore,
            accentColor = CyberSecondary,
            testTag = "network_gauge"
        )
        CyberGaugeCard(
            label = "THERMAL",
            score = thermalScore,
            accentColor = if (thermalScore < 50) CyberRed else if (thermalScore < 75) CyberYellow else CyberGreen,
            testTag = "thermal_gauge"
        )
        CyberGaugeCard(
            label = "BATTERY EFF",
            score = batteryScore,
            accentColor = CyberGreen,
            testTag = "battery_gauge"
        )
    }
}

@Composable
fun CyberGaugeCard(
    label: String,
    score: Int,
    accentColor: Color,
    testTag: String,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .width(82.dp)
            .background(CyberCardBg.copy(alpha = 0.5f), shape = RoundedCornerShape(10.dp))
            .padding(8.dp)
            .testTag(testTag),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Box(
            contentAlignment = Alignment.Center,
            modifier = Modifier.size(60.dp)
        ) {
            val animatedProgress by animateFloatAsState(
                targetValue = score / 100f,
                animationSpec = tween(durationMillis = 800),
                label = "GaugeProgress"
            )

            Canvas(modifier = Modifier.size(54.dp)) {
                val strokeWidth = 5.dp.toPx()
                // Background arc (dimmed accent)
                drawArc(
                    color = accentColor.copy(alpha = 0.15f),
                    startAngle = 135f,
                    sweepAngle = 270f,
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
                // Active foreground arc with gradient
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(accentColor.copy(alpha = 0.4f), accentColor, accentColor)
                    ),
                    startAngle = 135f,
                    sweepAngle = 270f * animatedProgress,
                    useCenter = false,
                    style = Stroke(width = strokeWidth, cap = StrokeCap.Round)
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "$score",
                    color = CyberWhite,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "pts",
                    color = CyberGray,
                    fontSize = 8.sp
                )
            }
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = label,
            color = CyberGray,
            fontSize = 9.sp,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1
        )
    }
}
