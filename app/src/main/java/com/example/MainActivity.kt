package com.example

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.viewModels
import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.data.database.AgiDatabase
import com.example.data.repository.AgiRepository
import com.example.ui.components.*
import com.example.ui.theme.MyApplicationTheme
import com.example.ui.theme.*
import com.example.ui.viewmodel.AgiViewModel
import com.example.ui.viewmodel.AgiViewModelFactory
import com.example.ui.viewmodel.GamingMode
import com.example.ui.viewmodel.TelemetryState

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        // 1. Setup Room Database & Repository
        val database = AgiDatabase.getDatabase(this)
        val repository = AgiRepository(database.agiDao())

        setContent {
            MyApplicationTheme {
                val viewModel: AgiViewModel = androidx.lifecycle.viewmodel.compose.viewModel(
                    factory = AgiViewModelFactory(application, repository)
                )

                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = CyberBg
                ) {
                    AgiGamingOSApp(viewModel)
                }
            }
        }
    }
}

@Composable
fun AgiGamingOSApp(viewModel: AgiViewModel) {
    // --- Collect States ---
    val telemetry by viewModel.telemetry.collectAsState()
    val currentMode by viewModel.currentMode.collectAsState()
    val diagnosis by viewModel.diagnosis.collectAsState()
    val isOptimizing by viewModel.optimizationActive.collectAsState()
    val optProgress by viewModel.optimizationProgress.collectAsState()

    val deviceDna by viewModel.deviceDna.collectAsState()
    val pastSessions by viewModel.pastSessions.collectAsState()
    val optimizations by viewModel.optimizationLogList.collectAsState()
    val rollbacks by viewModel.rollbackLogList.collectAsState()
    val aiRecommendations by viewModel.aiCoachRecommendations.collectAsState()
    val communityStats by viewModel.communityStats.collectAsState()

    val fpsHistory by viewModel.fpsHistory.collectAsState()
    val tempHistory by viewModel.tempHistory.collectAsState()
    val pingHistory by viewModel.pingHistory.collectAsState()

    val chatMessages by viewModel.chatMessages.collectAsState()
    val isAiLoading by viewModel.isAiLoading.collectAsState()
    val digitalTwinPredictions by viewModel.digitalTwinPredictions.collectAsState()

    // --- Tab Navigation State ---
    var activeTab by remember { mutableStateOf(0) } // 0: Cockpit, 1: Modes, 2: Diagnostics, 3: AI Coach, 4: Database

    val scrollState = rememberScrollState()
    val context = LocalContext.current

    Box(modifier = Modifier.fillMaxSize()) {
        // MAIN COCKPIT BODY
        Scaffold(
            bottomBar = {
                AgiBottomNavBar(
                    activeTab = activeTab,
                    onTabSelected = { activeTab = it }
                )
            },
            containerColor = CyberBg
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .padding(horizontal = 16.dp)
                    .verticalScroll(scrollState)
            ) {
                Spacer(modifier = Modifier.height(36.dp)) // Safe status bar padding

                // AGI HUD HEADER
                AgiHeaderPanel(
                    username = "NEONGHOST_99",
                    currentMode = currentMode.modeName,
                    batteryLevel = telemetry.batteryLevel,
                    deviceModel = deviceDna?.model ?: "Android Device"
                )

                Spacer(modifier = Modifier.height(14.dp))

                // DYNAMIC VIEW NAVIGATION SWITCH
                when (activeTab) {
                    0 -> {
                        // TAB 0: COCKPIT (Main Dashboard)
                        // Glowing Cyber Scores
                        CyberGaugesRow(
                            performanceScore = deviceDna?.gamingScore ?: 85,
                            networkScore = deviceDna?.networkScore ?: 90,
                            thermalScore = (100 - (telemetry.temperature * 1.5f).toInt()).coerceIn(10, 100),
                            batteryScore = (100 - (telemetry.cpuUsage * 0.4f).toInt()).coerceIn(40, 100)
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Large Glowing Control Buttons
                        AgiActionController(
                            isOptimizing = isOptimizing,
                            optProgress = optProgress,
                            onAnalyze = {
                                Toast.makeText(context, "Mendiagnosis performa hardware: ${diagnosis.title}", Toast.LENGTH_LONG).show()
                            },
                            onOptimize = {
                                Toast.makeText(context, "Memulai optimasi & prediksi digital twin...", Toast.LENGTH_SHORT).show()
                                viewModel.optimizeDevice()
                            }
                        )

                        Spacer(modifier = Modifier.height(18.dp))

                        // Real-time grid gauges
                        TelemetryHudGrid(
                            fps = telemetry.fps,
                            cpuUsage = telemetry.cpuUsage,
                            gpuUsage = telemetry.gpuUsage,
                            ramUsed = telemetry.ramUsedGb,
                            ramTotal = telemetry.ramTotalGb,
                            temperature = telemetry.temperature,
                            ping = telemetry.pingMs
                        )

                        Spacer(modifier = Modifier.height(16.dp))

                        // Live analytics wave chart
                        TelemetryWaveChart(
                            fpsHistory = fpsHistory,
                            tempHistory = tempHistory,
                            pingHistory = pingHistory
                        )

                        Spacer(modifier = Modifier.height(20.dp))
                    }

                    1 -> {
                        // TAB 1: MODESSELECTOR
                        ModesSelectorSection(
                            currentMode = currentMode,
                            onModeSelected = { viewModel.selectMode(it) },
                            customTargetFps = viewModel.customTargetFps,
                            customTargetTemp = viewModel.customTargetTemp,
                            customNetPriority = viewModel.customNetPriority
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                    }

                    2 -> {
                        // TAB 2: DIAGNOSTICS & TWIN
                        DigitalTwinSection(
                            diagnosis = diagnosis,
                            predictions = digitalTwinPredictions
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                    }

                    3 -> {
                        // TAB 3: AI PERFORMANCE COACH
                        AiCoachSection(
                            chatMessages = chatMessages,
                            isAiLoading = isAiLoading,
                            aiRecommendations = aiRecommendations,
                            onSendMessage = { viewModel.sendChatMessage(it) }
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                    }

                    4 -> {
                        // TAB 4: HISTORIC SESSION REPORTS & DB
                        SessionReportsSection(
                            sessions = pastSessions,
                            optimizations = optimizations,
                            rollbacks = rollbacks,
                            communityStats = communityStats
                        )
                        Spacer(modifier = Modifier.height(20.dp))
                    }
                }
            }
        }

        // SLIDING GAMING SIDEBAR OVERLAY HUD (Can be pulled out anytime from the right edge!)
        SidebarOverlayWidget(
            fps = telemetry.fps,
            frameTimeMs = telemetry.frameTimeMs,
            cpuUsage = telemetry.cpuUsage,
            gpuUsage = telemetry.gpuUsage,
            ramUsed = telemetry.ramUsedGb,
            ramTotal = telemetry.ramTotalGb,
            temperature = telemetry.temperature,
            ping = telemetry.pingMs,
            onQuickOptimize = {
                viewModel.optimizeDevice()
            },
            onNavigateToCoach = {
                activeTab = 3
            },
            onNavigateToReports = {
                activeTab = 4
            }
        )
    }
}

@Composable
fun AgiHeaderPanel(
    username: String,
    currentMode: String,
    batteryLevel: Int,
    deviceModel: String
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(CyberAccent.copy(alpha = 0.08f), Color.Transparent)
                )
            )
            .border(1.dp, CyberAccent.copy(alpha = 0.15f), shape = RoundedCornerShape(12.dp))
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(10.dp)
                            .background(CyberAccent, shape = CircleShape)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "AGI COMPILER ENGINE",
                        color = CyberAccent,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 1.sp
                    )
                }
                Spacer(modifier = Modifier.height(2.dp))
                Text(
                    text = deviceModel.uppercase(),
                    color = CyberWhite,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = currentMode.uppercase(),
                    color = CyberAccent,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    fontFamily = FontFamily.Monospace
                )
                Text(
                    text = "BATERAI: $batteryLevel%",
                    color = if (batteryLevel < 20) CyberRed else CyberGreen,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
fun AgiActionController(
    isOptimizing: Boolean,
    optProgress: Float,
    onAnalyze: () -> Unit,
    onOptimize: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Big Optimization Button
        Button(
            onClick = onOptimize,
            modifier = Modifier
                .weight(1.3f)
                .height(52.dp)
                .testTag("optimize_button"),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent
            ),
            contentPadding = PaddingValues(),
            shape = RoundedCornerShape(12.dp),
            enabled = !isOptimizing
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.horizontalGradient(
                            if (isOptimizing) listOf(CyberGray, CyberBg)
                            else listOf(CyberAccent, CyberSecondary)
                        )
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (isOptimizing) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        CircularProgressIndicator(
                            color = CyberAccent,
                            strokeWidth = 2.dp,
                            modifier = Modifier.size(18.dp)
                        )
                        Spacer(modifier = Modifier.width(10.dp))
                        Text(
                            text = "MENGOPTIMALKAN ${(optProgress * 100).toInt()}%",
                            color = CyberWhite,
                            fontSize = 11.sp,
                            fontWeight = FontWeight.Bold,
                            letterSpacing = 1.sp
                        )
                    }
                } else {
                    Text(
                        text = "OPTIMIZE DEVICE",
                        color = CyberBg,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Black,
                        letterSpacing = 1.2.sp
                    )
                }
            }
        }

        // Diagnosis/Analyze Button
        Button(
            onClick = onAnalyze,
            modifier = Modifier
                .weight(1f)
                .height(52.dp)
                .border(1.dp, CyberAccent, shape = RoundedCornerShape(12.dp))
                .testTag("analyze_button"),
            colors = ButtonDefaults.buttonColors(
                containerColor = Color.Transparent
            ),
            shape = RoundedCornerShape(12.dp)
        ) {
            Text(
                text = "DIAGNOSE",
                color = CyberAccent,
                fontSize = 12.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp
            )
        }
    }
}

@Composable
fun AgiBottomNavBar(
    activeTab: Int,
    onTabSelected: (Int) -> Unit
) {
    NavigationBar(
        containerColor = CyberCardBg,
        tonalElevation = 10.dp,
        modifier = Modifier.windowInsetsPadding(WindowInsets.navigationBars)
    ) {
        NavigationBarItem(
            selected = activeTab == 0,
            onClick = { onTabSelected(0) },
            icon = { Icon(Icons.Default.Home, contentDescription = "Dashboard", tint = if (activeTab == 0) CyberAccent else CyberGray) },
            label = { Text("COCKPIT", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = if (activeTab == 0) CyberAccent else CyberGray) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = CyberAccent.copy(alpha = 0.15f)
            ),
            modifier = Modifier.testTag("nav_cockpit")
        )
        NavigationBarItem(
            selected = activeTab == 1,
            onClick = { onTabSelected(1) },
            icon = { Icon(Icons.Default.Settings, contentDescription = "Modes", tint = if (activeTab == 1) CyberAccent else CyberGray) },
            label = { Text("MODES", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = if (activeTab == 1) CyberAccent else CyberGray) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = CyberAccent.copy(alpha = 0.15f)
            ),
            modifier = Modifier.testTag("nav_modes")
        )
        NavigationBarItem(
            selected = activeTab == 2,
            onClick = { onTabSelected(2) },
            icon = { Icon(Icons.Default.Warning, contentDescription = "Twin", tint = if (activeTab == 2) CyberAccent else CyberGray) },
            label = { Text("TWIN", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = if (activeTab == 2) CyberAccent else CyberGray) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = CyberAccent.copy(alpha = 0.15f)
            ),
            modifier = Modifier.testTag("nav_diagnostics")
        )
        NavigationBarItem(
            selected = activeTab == 3,
            onClick = { onTabSelected(3) },
            icon = { Icon(Icons.Default.Face, contentDescription = "Tuning Console", tint = if (activeTab == 3) CyberAccent else CyberGray) },
            label = { Text("TUNING", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = if (activeTab == 3) CyberAccent else CyberGray) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = CyberAccent.copy(alpha = 0.15f)
            ),
            modifier = Modifier.testTag("nav_coach")
        )
        NavigationBarItem(
            selected = activeTab == 4,
            onClick = { onTabSelected(4) },
            icon = { Icon(Icons.Default.List, contentDescription = "Database", tint = if (activeTab == 4) CyberAccent else CyberGray) },
            label = { Text("TRACE DB", fontSize = 9.sp, fontWeight = FontWeight.Bold, color = if (activeTab == 4) CyberAccent else CyberGray) },
            colors = NavigationBarItemDefaults.colors(
                indicatorColor = CyberAccent.copy(alpha = 0.15f)
            ),
            modifier = Modifier.testTag("nav_database")
        )
    }
}
