package com.example.ui.components

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.ui.theme.*
import com.example.ui.viewmodel.DiagnosisResult

@Composable
fun DigitalTwinSection(
    diagnosis: DiagnosisResult,
    predictions: List<com.example.ui.viewmodel.AgiViewModel.TwinPrediction>,
    modifier: Modifier = Modifier
) {
    var selectedPredictionIdx by remember { mutableStateOf(0) }

    Column(modifier = modifier.fillMaxWidth()) {
        // 1. Diagnosis Engine Panel
        Text(
            text = "PUSAT DIAGNOSIS HARDWARE",
            color = CyberWhite,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(8.dp))

        val severityColor = when (diagnosis.severity) {
            "CRITICAL" -> CyberRed
            "WARNING" -> CyberYellow
            else -> CyberGreen
        }

        val severityBg = severityColor.copy(alpha = 0.08f)

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(severityBg, shape = RoundedCornerShape(12.dp))
                .border(1.dp, severityColor.copy(alpha = 0.3f), shape = RoundedCornerShape(12.dp))
                .padding(14.dp)
                .testTag("diagnosis_card")
        ) {
            Column {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = diagnosis.title.uppercase(),
                        color = severityColor,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold,
                        letterSpacing = 0.5.sp
                    )
                    Box(
                        modifier = Modifier
                            .background(severityColor.copy(alpha = 0.15f), shape = RoundedCornerShape(4.dp))
                            .padding(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = "IKM: ${diagnosis.confidenceScore}%",
                            color = severityColor,
                            fontSize = 8.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = diagnosis.rootCause,
                    color = CyberWhite,
                    fontSize = 11.sp,
                    lineHeight = 15.sp
                )
                Spacer(modifier = Modifier.height(10.dp))
                Text(
                    text = "REKOMENDASI NYATA:",
                    color = CyberGray,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = diagnosis.recommendation,
                    color = CyberAccent,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 2. Digital Twin Section
        Text(
            text = "PREDIKSI DIGITAL TWIN",
            color = CyberWhite,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Prediksi dampak optimasi berdasarkan status hardware real-time.",
            color = CyberGray,
            fontSize = 11.sp
        )
        Spacer(modifier = Modifier.height(12.dp))

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            // Left Column: List of optimization tweaks
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                predictions.forEachIndexed { idx, pred ->
                    val isSelected = idx == selectedPredictionIdx
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                if (isSelected) CyberAccent.copy(alpha = 0.1f) else CyberCardBg,
                                shape = RoundedCornerShape(8.dp)
                            )
                            .border(
                                1.dp,
                                if (isSelected) CyberAccent else CyberWhite.copy(alpha = 0.05f),
                                shape = RoundedCornerShape(8.dp)
                            )
                            .clickable { selectedPredictionIdx = idx }
                            .padding(10.dp)
                            .testTag("twin_item_$idx")
                    ) {
                        Text(
                            text = pred.name,
                            color = if (isSelected) CyberAccent else CyberWhite,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Right Column: Simulated outcome readouts
            val activePrediction = predictions[selectedPredictionIdx]
            Column(
                modifier = Modifier
                    .weight(1.2f)
                    .background(CyberCardBg, shape = RoundedCornerShape(12.dp))
                    .border(1.dp, CyberWhite.copy(alpha = 0.05f), shape = RoundedCornerShape(12.dp))
                    .padding(14.dp)
                    .testTag("twin_details_panel")
            ) {
                Text(
                    text = "PREDIKSI HASIL",
                    color = CyberGray,
                    fontSize = 9.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(6.dp))
                Text(
                    text = activePrediction.name.uppercase(),
                    color = CyberWhite,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(12.dp))

                // Metric Changes
                TwinMetricRow(label = "Dampak FPS Rata-Rata:", value = activePrediction.fpsChange, color = CyberGreen)
                TwinMetricRow(label = "Dampak Termal/Suhu:", value = activePrediction.thermalChange, color = if (activePrediction.thermalChange.contains("Panas")) CyberRed else CyberGreen)

                Spacer(modifier = Modifier.height(14.dp))

                // Confidence score bar
                Text(
                    text = "TINGKAT KEPERCAYAAN PREDIKSI",
                    color = CyberGray,
                    fontSize = 8.sp,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    LinearProgressIndicator(
                        progress = activePrediction.confidence / 100f,
                        color = CyberAccent,
                        trackColor = CyberWhite.copy(alpha = 0.1f),
                        modifier = Modifier
                            .weight(1f)
                            .height(4.dp)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "${activePrediction.confidence}%",
                        color = CyberAccent,
                        fontSize = 10.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
fun TwinMetricRow(label: String, value: String, color: Color) {
    Column(modifier = Modifier.padding(vertical = 4.dp)) {
        Text(text = label, color = CyberGray, fontSize = 9.sp)
        Text(text = value, color = color, fontSize = 11.sp, fontWeight = FontWeight.Bold)
    }
}
