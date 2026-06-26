package com.example.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.text.TextStyle
import com.example.data.entity.AiRecommendationEntity
import com.example.ui.theme.*

@Composable
fun AiCoachSection(
    chatMessages: List<Pair<String, Boolean>>,
    isAiLoading: Boolean,
    aiRecommendations: List<AiRecommendationEntity>,
    onSendMessage: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    var queryText by remember { mutableStateOf("") }

    Column(modifier = modifier.fillMaxWidth()) {
        Text(
            text = "KONSOL TUNING & DIAGNOSIS LOKAL",
            color = CyberWhite,
            fontSize = 12.sp,
            fontWeight = FontWeight.Bold,
            letterSpacing = 0.8.sp
        )
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = "Analisis bottleneck hardware instan & eksekusi kompilasi sistem 100% lokal dan offline.",
            color = CyberGray,
            fontSize = 11.sp
        )

        Spacer(modifier = Modifier.height(14.dp))

        // 1. Local Recommendation Cards
        if (aiRecommendations.isNotEmpty()) {
            Text(
                text = "HASIL DIAGNOSIS TELEMETRI AKTIF",
                color = CyberAccent,
                fontSize = 9.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.5.sp
            )
            Spacer(modifier = Modifier.height(6.dp))

            // Show latest recommendation
            val latestRec = aiRecommendations.first()
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(CyberAccent.copy(alpha = 0.05f), shape = RoundedCornerShape(12.dp))
                    .border(1.dp, CyberAccent.copy(alpha = 0.2f), shape = RoundedCornerShape(12.dp))
                    .padding(12.dp)
                    .testTag("ai_rec_card")
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Text(
                            text = "DIAGNOSA: ${latestRec.triggerType.uppercase()}",
                            color = CyberAccent,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "ESTIMASI: ${latestRec.estimatedGain}",
                            color = CyberGreen,
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Bold
                        )
                    }
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = latestRec.adviceText,
                        color = CyberWhite,
                        fontSize = 11.sp,
                        lineHeight = 15.sp
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(20.dp))

        // 2. Chat Terminal
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(260.dp)
                .background(CyberCardBg, shape = RoundedCornerShape(14.dp))
                .border(1.dp, CyberWhite.copy(alpha = 0.05f), shape = RoundedCornerShape(14.dp))
                .padding(12.dp)
        ) {
            Column(modifier = Modifier.fillMaxSize()) {
                // Scrollable Chat Area
                LazyColumn(
                    modifier = Modifier
                        .weight(1f)
                        .fillMaxWidth()
                        .testTag("chat_history"),
                    verticalArrangement = Arrangement.spacedBy(10.dp),
                    reverseLayout = false
                ) {
                    items(chatMessages) { message ->
                        val isUser = message.second
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start
                        ) {
                            Box(
                                modifier = Modifier
                                    .widthIn(max = 280.dp)
                                    .background(
                                        if (isUser) CyberSecondary.copy(alpha = 0.2f) else CyberWhite.copy(alpha = 0.06f),
                                        shape = RoundedCornerShape(
                                            topStart = 12.dp,
                                            topEnd = 12.dp,
                                            bottomStart = if (isUser) 12.dp else 0.dp,
                                            bottomEnd = if (isUser) 0.dp else 12.dp
                                        )
                                    )
                                    .border(
                                        1.dp,
                                        if (isUser) CyberSecondary else CyberWhite.copy(alpha = 0.1f),
                                        shape = RoundedCornerShape(
                                            topStart = 12.dp,
                                            topEnd = 12.dp,
                                            bottomStart = if (isUser) 12.dp else 0.dp,
                                            bottomEnd = if (isUser) 0.dp else 12.dp
                                        )
                                    )
                                    .padding(10.dp)
                            ) {
                                Text(
                                    text = message.first,
                                    color = CyberWhite,
                                    fontSize = 11.sp,
                                    lineHeight = 15.sp,
                                    fontFamily = FontFamily.Monospace
                                )
                            }
                        }
                    }

                    if (isAiLoading) {
                        item {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.Start
                            ) {
                                Box(
                                    modifier = Modifier
                                        .background(CyberWhite.copy(alpha = 0.06f), shape = RoundedCornerShape(12.dp))
                                        .padding(10.dp)
                                ) {
                                    Text(
                                        text = "KONSOL: Mengompilasi parameter sistem...",
                                        color = CyberAccent,
                                        fontSize = 10.sp,
                                        fontWeight = FontWeight.Bold,
                                        fontFamily = FontFamily.Monospace
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(10.dp))

                // Input Bar
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    OutlinedTextField(
                        value = queryText,
                        onValueChange = { queryText = it },
                        placeholder = { Text("Ketik perintah (contoh: 'status', 'suhu', 'optimasi')...", color = CyberGray, fontSize = 11.sp) },
                        modifier = Modifier
                            .weight(1f)
                            .height(48.dp)
                            .testTag("chat_input"),
                        textStyle = TextStyle(color = CyberWhite, fontSize = 11.sp, fontFamily = FontFamily.Monospace),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = CyberAccent,
                            unfocusedBorderColor = CyberWhite.copy(alpha = 0.1f),
                            focusedContainerColor = CyberBg,
                            unfocusedContainerColor = CyberBg
                        ),
                        shape = RoundedCornerShape(24.dp),
                        singleLine = true
                    )

                    IconButton(
                        onClick = {
                            if (queryText.isNotBlank()) {
                                onSendMessage(queryText)
                                queryText = ""
                            }
                        },
                        modifier = Modifier
                            .size(40.dp)
                            .background(
                                brush = Brush.radialGradient(listOf(CyberAccent, CyberSecondary)),
                                shape = RoundedCornerShape(20.dp)
                            )
                            .testTag("send_chat_button"),
                        enabled = !isAiLoading
                    ) {
                        Icon(
                            imageVector = Icons.Default.Send,
                            contentDescription = "Send Chat",
                            tint = CyberBg,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }
        }
    }
}
