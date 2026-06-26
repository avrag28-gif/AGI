package com.example.data.dao

import androidx.room.*
import com.example.data.entity.*
import kotlinx.coroutines.flow.Flow

@Dao
interface AgiDao {
    // --- User Queries ---
    @Query("SELECT * FROM users LIMIT 1")
    fun getUser(): Flow<UserEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertUser(user: UserEntity)

    // --- Device DNA ---
    @Query("SELECT * FROM device_dna LIMIT 1")
    fun getDeviceDna(): Flow<DeviceDnaEntity?>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertDeviceDna(dna: DeviceDnaEntity)

    // --- Sessions ---
    @Query("SELECT * FROM sessions ORDER BY timestamp DESC")
    fun getAllSessions(): Flow<List<SessionEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertSession(session: SessionEntity): Long

    // --- Telemetry logs ---
    @Query("SELECT * FROM fps_logs WHERE sessionId = :sessionId ORDER BY timestamp ASC")
    fun getFpsLogsForSession(sessionId: Int): Flow<List<FpsLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertFpsLog(log: FpsLogEntity)

    @Query("SELECT * FROM temperature_logs WHERE sessionId = :sessionId ORDER BY timestamp ASC")
    fun getTempLogsForSession(sessionId: Int): Flow<List<TemperatureLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTempLog(log: TemperatureLogEntity)

    @Query("SELECT * FROM network_logs WHERE sessionId = :sessionId ORDER BY timestamp ASC")
    fun getNetworkLogsForSession(sessionId: Int): Flow<List<NetworkLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertNetworkLog(log: NetworkLogEntity)

    // --- Optimization Logs ---
    @Query("SELECT * FROM optimization_logs ORDER BY timestamp DESC")
    fun getAllOptimizations(): Flow<List<OptimizationLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertOptimization(log: OptimizationLogEntity): Long

    @Query("UPDATE optimization_logs SET rolledBack = 1 WHERE id = :id")
    suspend fun markOptimizationAsRolledBack(id: Int)

    // --- Rollback Logs ---
    @Query("SELECT * FROM rollback_logs ORDER BY timestamp DESC")
    fun getAllRollbacks(): Flow<List<RollbackLogEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRollback(log: RollbackLogEntity)

    // --- AI Recommendations ---
    @Query("SELECT * FROM ai_recommendations ORDER BY timestamp DESC")
    fun getAiRecommendations(): Flow<List<AiRecommendationEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAiRecommendation(rec: AiRecommendationEntity)

    // --- Community Stats ---
    @Query("SELECT * FROM community_statistics ORDER BY optimizationSuccessRate DESC")
    fun getCommunityStatistics(): Flow<List<CommunityStatisticEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertCommunityStatistic(stat: CommunityStatisticEntity)
}
