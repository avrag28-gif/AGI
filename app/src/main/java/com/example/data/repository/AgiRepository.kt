package com.example.data.repository

import android.os.Build
import com.example.data.dao.AgiDao
import com.example.data.entity.*
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.firstOrNull

class AgiRepository(private val agiDao: AgiDao) {

    val user: Flow<UserEntity?> = agiDao.getUser()
    val deviceDna: Flow<DeviceDnaEntity?> = agiDao.getDeviceDna()
    val sessions: Flow<List<SessionEntity>> = agiDao.getAllSessions()
    val optimizations: Flow<List<OptimizationLogEntity>> = agiDao.getAllOptimizations()
    val rollbacks: Flow<List<RollbackLogEntity>> = agiDao.getAllRollbacks()
    val aiRecommendations: Flow<List<AiRecommendationEntity>> = agiDao.getAiRecommendations()
    val communityStatistics: Flow<List<CommunityStatisticEntity>> = agiDao.getCommunityStatistics()

    suspend fun insertUser(user: UserEntity) = agiDao.insertUser(user)
    suspend fun insertDeviceDna(dna: DeviceDnaEntity) = agiDao.insertDeviceDna(dna)
    suspend fun insertSession(session: SessionEntity): Long = agiDao.insertSession(session)
    suspend fun insertFpsLog(log: FpsLogEntity) = agiDao.insertFpsLog(log)
    suspend fun insertTempLog(log: TemperatureLogEntity) = agiDao.insertTempLog(log)
    suspend fun insertNetworkLog(log: NetworkLogEntity) = agiDao.insertNetworkLog(log)
    suspend fun insertOptimization(log: OptimizationLogEntity): Long = agiDao.insertOptimization(log)
    suspend fun markOptimizationAsRolledBack(id: Int) = agiDao.markOptimizationAsRolledBack(id)
    suspend fun insertRollback(log: RollbackLogEntity) = agiDao.insertRollback(log)
    suspend fun insertAiRecommendation(rec: AiRecommendationEntity) = agiDao.insertAiRecommendation(rec)
    suspend fun insertCommunityStatistic(stat: CommunityStatisticEntity) = agiDao.insertCommunityStatistic(stat)

    suspend fun populateInitialDataIfEmpty() {
        // Only run if the database has no sessions/DNA
        val existingDna = deviceDna.firstOrNull()
        if (existingDna == null) {
            // 1. Save local user
            agiDao.insertUser(
                UserEntity(
                    id = "local_gamer",
                    username = "NeonGhost_99",
                    isPremium = true,
                    gamingLevel = "Competitive Elite"
                )
            )

            // 2. Save device DNA (Realistic values based on Android platform)
            val modelName = Build.MODEL ?: "Unknown Device"
            val chipset = Build.HARDWARE ?: "Snapdragon 8 Gen 2"
            agiDao.insertDeviceDna(
                DeviceDnaEntity(
                    id = "local_device",
                    model = modelName,
                    gamingScore = 88,
                    thermalScore = 79,
                    networkScore = 91,
                    pattern = "Aggressive Thermal Sensitive"
                )
            )

            // 3. Save community statistics
            val sampleStats = listOf(
                CommunityStatisticEntity(deviceModel = modelName, gameTitle = "Genshin Impact", avgFps = 58, avgTemp = 44.5f, optimizationSuccessRate = 89),
                CommunityStatisticEntity(deviceModel = modelName, gameTitle = "PUBG Mobile", avgFps = 89, avgTemp = 41.2f, optimizationSuccessRate = 94),
                CommunityStatisticEntity(deviceModel = modelName, gameTitle = "Mobile Legends", avgFps = 119, avgTemp = 38.6f, optimizationSuccessRate = 96),
                CommunityStatisticEntity(deviceModel = "ROG Phone 8", gameTitle = "Genshin Impact", avgFps = 60, avgTemp = 42.1f, optimizationSuccessRate = 95)
            )
            for (stat in sampleStats) {
                agiDao.insertCommunityStatistic(stat)
            }

            // 4. Save some historical gaming sessions
            val session1 = SessionEntity(
                gameId = 1,
                gameTitle = "Genshin Impact",
                durationSeconds = 1800, // 30 mins
                avgFps = 54,
                minFps = 38,
                maxFps = 60,
                frameStability = 78,
                avgPing = 45,
                packetLossPct = 0.2f,
                peakTemp = 45.2f,
                grade = "B+",
                batteryUsagePct = 12.5f
            )
            val session2 = SessionEntity(
                gameId = 2,
                gameTitle = "PUBG Mobile",
                durationSeconds = 2400, // 40 mins
                avgFps = 88,
                minFps = 72,
                maxFps = 90,
                frameStability = 91,
                avgPing = 32,
                packetLossPct = 0.1f,
                peakTemp = 41.8f,
                grade = "A",
                batteryUsagePct = 14.2f
            )
            val s1Id = agiDao.insertSession(session1).toInt()
            val s2Id = agiDao.insertSession(session2).toInt()

            // 5. Populate some telemetry logs for these sessions
            // Session 1 Fps Logs
            val s1Fps = listOf(55, 54, 52, 41, 38, 59, 60, 58, 55, 54)
            s1Fps.forEachIndexed { idx, fps ->
                agiDao.insertFpsLog(FpsLogEntity(sessionId = s1Id, fpsValue = fps, timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
                agiDao.insertTempLog(TemperatureLogEntity(sessionId = s1Id, tempValue = 40f + idx * 0.5f, timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
                agiDao.insertNetworkLog(NetworkLogEntity(sessionId = s1Id, ping = 40 + (idx % 3) * 5, jitter = 2 + (idx % 2), packetLoss = 0.1f * (idx % 2), timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
            }

            // Session 2 Fps Logs
            val s2Fps = listOf(89, 90, 88, 87, 89, 90, 88, 89, 87, 88)
            s2Fps.forEachIndexed { idx, fps ->
                agiDao.insertFpsLog(FpsLogEntity(sessionId = s2Id, fpsValue = fps, timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
                agiDao.insertTempLog(TemperatureLogEntity(sessionId = s2Id, tempValue = 38f + idx * 0.3f, timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
                agiDao.insertNetworkLog(NetworkLogEntity(sessionId = s2Id, ping = 30 + (idx % 2) * 4, jitter = 1 + (idx % 2), packetLoss = 0.05f * (idx % 2), timestamp = System.currentTimeMillis() - (10 - idx) * 10000))
            }

            // 6. Save some optimization logs
            agiDao.insertOptimization(
                OptimizationLogEntity(
                    actionName = "CPU Core Affinity Lock",
                    expectedGain = "+3 FPS",
                    confidenceScore = 88,
                    rolledBack = false
                )
            )
            agiDao.insertOptimization(
                OptimizationLogEntity(
                    actionName = "Network Priority Route",
                    expectedGain = "-8ms Jitter",
                    confidenceScore = 92,
                    rolledBack = false
                )
            )

            // 7. Save initial AI recommendations
            agiDao.insertAiRecommendation(
                AiRecommendationEntity(
                    triggerType = "Thermal",
                    adviceText = "Suhu meningkat mencapai 43.5°C di Genshin Impact. Menurunkan render quality ke Medium akan mengurangi panas 3°C tanpa mengurangi kenyamanan visual.",
                    estimatedGain = "-3°C Thermal Wear"
                )
            )
            agiDao.insertAiRecommendation(
                AiRecommendationEntity(
                    triggerType = "Network",
                    adviceText = "Ping berfluktuasi antara 45ms hingga 95ms. Aktifkan Dual-Channel Acceleration untuk menggabungkan Wi-Fi + Mobile Data.",
                    estimatedGain = "-12ms Jitter Reduction"
                )
            )
        }
    }
}
