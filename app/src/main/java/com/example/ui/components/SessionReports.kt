package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.entity.*
import com.example.ui.theme.*
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@Composable
fun SessionReportsSection(
    sessions: List<SessionEntity>,
    optimizations: List<OptimizationLogEntity>,
    rollbacks: List<RollbackLogEntity>,
    communityStats: List<CommunityStatisticEntity>,
    modifier: Modifier = Modifier
) {
    var activeSubTab by remember { mutableStateOf(0) } // 0: Sesi, 1: Optimasi & Rollback, 2: Komunitas

    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = "LOG ANALYTICS & DATABASE",
            color = CyberWhite,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(10.dp))

        // Sub Tab Selector
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(CyberCardBg, shape = RoundedCornerShape(8.dp))
                .padding(4.dp),
            horizontalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            SubTabBtn(text = "Sesi Bermain", active = activeSubTab == 0, modifier = Modifier.weight(1f)) { activeSubTab = 0 }
            SubTabBtn(text = "Optimasi Trace", active = activeSubTab == 1, modifier = Modifier.weight(1.2f)) { activeSubTab = 1 }
            SubTabBtn(text = "Komunitas", active = activeSubTab == 2, modifier = Modifier.weight(1f)) { activeSubTab = 2 }
        }

        Spacer(modifier = Modifier.height(14.dp))

        // Content lists
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(320.dp)
        ) {
            when (activeSubTab) {
                0 -> {
                    // List of past play sessions
                    if (sessions.isEmpty()) {
                        EmptyStatePlaceholder(text = "Belum ada sesi bermain tersimpan. Selesaikan sesi bermain untuk menyimpan laporan.")
                    } else {
                        LazyColumn(
                            verticalArrangement = Arrangement.spacedBy(10.dp),
                            modifier = Modifier.fillMaxSize().testTag("sessions_list")
                        ) {
                            items(sessions) { session ->
                                PlaySessionCard(session)
                            }
                        }
                    }
                }
                1 -> {
                    // Optimization and Rollback traces
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                        modifier = Modifier.fillMaxSize().testTag("traces_list")
                    ) {
                        item {
                            Text(
                                text = "TRACING LOG OPTIMASI (${optimizations.size} DIAKTIFKAN)",
                                color = CyberAccent,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.5.sp,
                                modifier = Modifier.padding(bottom = 6.dp)
                            )
                        }

                        if (optimizations.isEmpty()) {
                            item {
                                EmptyStatePlaceholder(text = "Belum ada log tindakan optimasi.")
                            }
                        } else {
                            items(optimizations) { opt ->
                                OptimizationLogCard(opt)
                            }
                        }

                        item {
                            Text(
                                text = "LOG AUTOMATIC SYSTEM ROLLBACK (${rollbacks.size} DIPULIHKAN)",
                                color = CyberRed,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.5.sp,
                                modifier = Modifier.padding(top = 16.dp, bottom = 6.dp)
                            )
                        }

                        if (rollbacks.isEmpty()) {
                            item {
                                Box(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .background(CyberGreen.copy(alpha = 0.05f), shape = RoundedCornerShape(8.dp))
                                        .border(1.dp, CyberGreen.copy(alpha = 0.2f), shape = RoundedCornerShape(8.dp))
                                        .padding(12.dp)
                                ) {
                                    Text(
                                        text = "Sistem Stabil: Zero-error rollback. Semua optimasi teruji aman.",
                                        color = CyberGreen,
                                        fontSize = 11.sp,
                                        textAlign = TextAlign.Center,
                                        modifier = Modifier.fillMaxWidth()
                                    )
                                }
                            }
                        } else {
                            items(rollbacks) { rb ->
                                RollbackLogCard(rb)
                            }
                        }
                    }
                }
                2 -> {
                    // Community statistics database
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(10.dp),
                        modifier = Modifier.fillMaxSize().testTag("community_list")
                    ) {
                        item {
                            Text(
                                text = "DATABASE KONFIGURASI GLOBAL (CROWD-SOURCED)",
                                color = CyberSecondary,
                                fontSize = 9.sp,
                                fontWeight = FontWeight.Bold,
                                letterSpacing = 0.5.sp,
                                modifier = Modifier.padding(bottom = 6.dp)
                            )
                        }

                        items(communityStats) { stat ->
                            CommunityStatCard(stat)
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun SubTabBtn(
    text: String,
    active: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .background(
                if (active) CyberAccent.copy(alpha = 0.15f) else Color.Transparent,
                shape = RoundedCornerShape(6.dp)
            )
            .clickable { onClick() }
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = if (active) CyberAccent else CyberGray,
            fontSize = 10.sp,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
fun PlaySessionCard(session: SessionEntity) {
    val formatter = remember { SimpleDateFormat("dd MMM, HH:mm", Locale.getDefault()) }
    val dateString = formatter.format(Date(session.timestamp))

    val gradeColor = when (session.grade) {
        "A+", "A" -> CyberGreen
        "B+", "B" -> CyberAccent
        else -> CyberYellow
    }

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CyberCardBg, shape = RoundedCornerShape(12.dp))
            .border(1.dp, CyberWhite.copy(alpha = 0.04f), shape = RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = session.gameTitle.uppercase(),
                    color = CyberWhite,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Durasi: ${session.durationSeconds / 60} menit | $dateString",
                    color = CyberGray,
                    fontSize = 9.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    SessionMetricItem(label = "Rata FPS", value = "${session.avgFps}", unit = "FPS")
                    SessionMetricItem(label = "Suhu Puncak", value = String.format("%.1f", session.peakTemp), unit = "°C")
                    SessionMetricItem(label = "Ping Rata", value = "${session.avgPing}", unit = "ms")
                    SessionMetricItem(label = "Baterai", value = String.format("%.1f", session.batteryUsagePct), unit = "%")
                }
            }

            // Glowing Grade Badge
            Box(
                modifier = Modifier
                    .size(50.dp)
                    .background(gradeColor.copy(alpha = 0.08f), shape = RoundedCornerShape(25.dp))
                    .border(1.5.dp, gradeColor, shape = RoundedCornerShape(25.dp)),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = session.grade,
                    color = gradeColor,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Black
                )
            }
        }
    }
}

@Composable
fun SessionMetricItem(label: String, value: String, unit: String) {
    Column {
        Text(text = label, color = CyberGray, fontSize = 8.sp)
        Row(verticalAlignment = Alignment.Bottom) {
            Text(text = value, color = CyberWhite, fontSize = 11.sp, fontWeight = FontWeight.Bold, fontFamily = FontFamily.Monospace)
            Spacer(modifier = Modifier.width(1.dp))
            Text(text = unit, color = CyberGray, fontSize = 7.sp)
        }
    }
}

@Composable
fun OptimizationLogCard(opt: OptimizationLogEntity) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CyberCardBg.copy(alpha = 0.5f), shape = RoundedCornerShape(10.dp))
            .border(
                1.dp,
                if (opt.rolledBack) CyberRed.copy(alpha = 0.15f) else CyberGreen.copy(alpha = 0.15f),
                shape = RoundedCornerShape(10.dp)
            )
            .padding(10.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = opt.actionName,
                    color = if (opt.rolledBack) CyberRed else CyberWhite,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "Gain المتوقع: ${opt.expectedGain} | Confidence: ${opt.confidenceScore}%",
                    color = CyberGray,
                    fontSize = 9.sp
                )
            }
            Box(
                modifier = Modifier
                    .background(
                        if (opt.rolledBack) CyberRed.copy(alpha = 0.15f) else CyberGreen.copy(alpha = 0.15f),
                        shape = RoundedCornerShape(4.dp)
                    )
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = if (opt.rolledBack) "ROLLEDBACK" else "ACTIVE",
                    color = if (opt.rolledBack) CyberRed else CyberGreen,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun RollbackLogCard(rb: RollbackLogEntity) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CyberRed.copy(alpha = 0.05f), shape = RoundedCornerShape(10.dp))
            .border(1.dp, CyberRed.copy(alpha = 0.2f), shape = RoundedCornerShape(10.dp))
            .padding(10.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    text = "ROLLBACK ID #${rb.optimizationId}",
                    color = CyberRed,
                    fontSize = 10.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "SUKSES",
                    color = CyberGreen,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = rb.rollbackReason,
                color = CyberWhite,
                fontSize = 11.sp,
                lineHeight = 15.sp
            )
        }
    }
}

@Composable
fun CommunityStatCard(stat: CommunityStatisticEntity) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(CyberCardBg, shape = RoundedCornerShape(12.dp))
            .border(1.dp, CyberWhite.copy(alpha = 0.04f), shape = RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column {
                    Text(text = stat.gameTitle, color = CyberWhite, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    Text(text = "Device: ${stat.deviceModel}", color = CyberGray, fontSize = 9.sp)
                }
                Box(
                    modifier = Modifier
                        .background(CyberAccent.copy(alpha = 0.12f), shape = RoundedCornerShape(4.dp))
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "Sukses: ${stat.optimizationSuccessRate}%",
                        color = CyberAccent,
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                SessionMetricItem(label = "Rerata FPS global", value = "${stat.avgFps}", unit = "FPS")
                SessionMetricItem(label = "Rerata Suhu global", value = String.format("%.1f", stat.avgTemp), unit = "°C")
            }
        }
    }
}

@Composable
fun EmptyStatePlaceholder(text: String) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(CyberCardBg, shape = RoundedCornerShape(12.dp))
            .border(1.dp, CyberWhite.copy(alpha = 0.04f), shape = RoundedCornerShape(12.dp))
            .padding(24.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = CyberGray,
            fontSize = 11.sp,
            textAlign = TextAlign.Center,
            lineHeight = 16.sp
        )
    }
}
