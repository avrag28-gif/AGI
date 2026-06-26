package com.example.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity(tableName = "users")
data class UserEntity(
    @PrimaryKey val id: String = "local_gamer",
    val username: String = "CyberGamer",
    val isPremium: Boolean = false,
    val gamingLevel: String = "Casual"
)

@Entity(tableName = "devices")
data class DeviceEntity(
    @PrimaryKey val id: String,
    val model: String,
    val chipset: String,
    val totalRamGb: Float,
    val totalStorageGb: Float
)

@Entity(tableName = "games")
data class GameEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val title: String,
    val packageName: String,
    val category: String
)

@Entity(tableName = "sessions")
data class SessionEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val gameId: Int,
    val gameTitle: String,
    val durationSeconds: Long,
    val avgFps: Int,
    val minFps: Int,
    val maxFps: Int,
    val frameStability: Int, // Percentage (e.g. 92%)
    val avgPing: Int,
    val packetLossPct: Float,
    val peakTemp: Float,
    val grade: String, // A+, A, B, C, D
    val batteryUsagePct: Float,
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(tableName = "fps_logs")
data class FpsLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val sessionId: Int,
    val fpsValue: Int,
    val timestamp: Long
)

@Entity(tableName = "temperature_logs")
data class TemperatureLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val sessionId: Int,
    val tempValue: Float,
    val timestamp: Long
)

@Entity(tableName = "network_logs")
data class NetworkLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val sessionId: Int,
    val ping: Int,
    val jitter: Int,
    val packetLoss: Float,
    val timestamp: Long
)

@Entity(tableName = "optimization_logs")
data class OptimizationLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val actionName: String,
    val expectedGain: String,
    val confidenceScore: Int,
    val timestamp: Long = System.currentTimeMillis(),
    val rolledBack: Boolean = false
)

@Entity(tableName = "rollback_logs")
data class RollbackLogEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val optimizationId: Int,
    val rollbackReason: String,
    val timestamp: Long = System.currentTimeMillis(),
    val success: Boolean = true
)

@Entity(tableName = "device_dna")
data class DeviceDnaEntity(
    @PrimaryKey val id: String = "local_device",
    val model: String,
    val gamingScore: Int,
    val thermalScore: Int,
    val networkScore: Int,
    val pattern: String // e.g. "Aggressive Thermal Sensitive"
)

@Entity(tableName = "ai_recommendations")
data class AiRecommendationEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val triggerType: String, // e.g. "GPU", "Thermal", "Network"
    val adviceText: String,
    val estimatedGain: String,
    val timestamp: Long = System.currentTimeMillis()
)

@Entity(tableName = "community_statistics")
data class CommunityStatisticEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val deviceModel: String,
    val gameTitle: String,
    val avgFps: Int,
    val avgTemp: Float,
    val optimizationSuccessRate: Int // Percentage
)
