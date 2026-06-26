package com.example.ui.components

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Slider
import androidx.compose.material3.SliderDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import com.example.ui.viewmodel.GamingMode
import kotlinx.coroutines.flow.MutableStateFlow

@Composable
fun ModesSelectorSection(
    currentMode: GamingMode,
    onModeSelected: (GamingMode) -> Unit,
    customTargetFps: MutableStateFlow<Int>,
    customTargetTemp: MutableStateFlow<Int>,
    customNetPriority: MutableStateFlow<Boolean>,
    modifier: Modifier = Modifier
) {
    val targetFps by customTargetFps.collectAsState()
    val targetTemp by customTargetTemp.collectAsState()
    val netPriority by customNetPriority.collectAsState()

    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = "MODE SISTEM OPTIMASI",
            color = CyberWhite,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Pilih satu dari 10 profil optimalisasi perangkat untuk game Anda.",
            color = CyberGray,
            fontSize = 11.sp
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Grid of modes
        LazyVerticalGrid(
            columns = GridCells.Fixed(2),
            horizontalArrangement = Arrangement.spacedBy(10.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
            modifier = Modifier
                .fillMaxWidth()
                .height(290.dp)
                .testTag("modes_grid")
        ) {
            items(GamingMode.values()) { mode ->
                val active = mode == currentMode
                Box(
                    modifier = Modifier
                        .background(
                            if (active) CyberAccent.copy(alpha = 0.12f) else CyberCardBg,
                            shape = RoundedCornerShape(10.dp)
                        )
                        .border(
                            1.dp,
                            if (active) CyberAccent else CyberWhite.copy(alpha = 0.08f),
                            shape = RoundedCornerShape(10.dp)
                        )
                        .clickable { onModeSelected(mode) }
                        .padding(10.dp)
                        .testTag("mode_item_${mode.name}")
                ) {
                    Column {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text(
                                text = mode.modeName.uppercase(),
                                color = if (active) CyberAccent else CyberWhite,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Bold
                            )
                            if (active) {
                                Box(
                                    modifier = Modifier
                                        .size(6.dp)
                                        .background(CyberAccent, shape = RoundedCornerShape(3.dp))
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = mode.description,
                            color = CyberGray,
                            fontSize = 9.sp,
                            lineHeight = 12.sp,
                            maxLines = 2
                        )
                    }
                }
            }
        }

        // Custom Mode Parameters Panel (Appears with animation)
        AnimatedVisibility(
            visible = currentMode == GamingMode.CUSTOM,
            enter = fadeIn() + expandVertically(),
            exit = fadeOut() + shrinkVertically()
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 16.dp)
                    .background(CyberCardBg, shape = RoundedCornerShape(14.dp))
                    .border(1.dp, CyberAccent.copy(alpha = 0.2f), shape = RoundedCornerShape(14.dp))
                    .padding(16.dp)
                    .testTag("custom_mode_panel")
            ) {
                Text(
                    text = "KONFIGURASI PARAMETER MANUAL",
                    color = CyberAccent,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Bold,
                    letterSpacing = 0.5.sp
                )
                Spacer(modifier = Modifier.height(14.dp))

                // 1. Target FPS Slider
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(text = "Target Limit Frame Rate", color = CyberWhite, fontSize = 11.sp)
                        Text(text = "$targetFps FPS", color = CyberAccent, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                    Slider(
                        value = targetFps.toFloat(),
                        onValueChange = { customTargetFps.value = it.toInt() },
                        valueRange = 30f..120f,
                        steps = 5,
                        colors = SliderDefaults.colors(
                            activeTrackColor = CyberAccent,
                            thumbColor = CyberAccent
                        )
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 2. Target Temperature Slider
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(text = "Target Thermal Limit", color = CyberWhite, fontSize = 11.sp)
                        Text(text = "$targetTemp °C", color = CyberYellow, fontSize = 11.sp, fontWeight = FontWeight.Bold)
                    }
                    Slider(
                        value = targetTemp.toFloat(),
                        onValueChange = { customTargetTemp.value = it.toInt() },
                        valueRange = 35f..50f,
                        colors = SliderDefaults.colors(
                            activeTrackColor = CyberYellow,
                            thumbColor = CyberYellow
                        )
                    )
                }

                Spacer(modifier = Modifier.height(10.dp))

                // 3. Network Priority switch
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(text = "Akselerasi Bandwidth", color = CyberWhite, fontSize = 11.sp)
                        Text(text = "Prioritaskan paket data game nirkabel", color = CyberGray, fontSize = 9.sp)
                    }
                    Switch(
                        checked = netPriority,
                        onCheckedChange = { customNetPriority.value = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = CyberBg,
                            checkedTrackColor = CyberAccent,
                            uncheckedThumbColor = CyberGray,
                            uncheckedTrackColor = CyberCardBg
                        )
                    )
                }
            }
        }
    }
}
