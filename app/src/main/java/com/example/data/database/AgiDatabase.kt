package com.example.data.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import com.example.data.dao.AgiDao
import com.example.data.entity.*

@Database(
    entities = [
        UserEntity::class,
        DeviceEntity::class,
        GameEntity::class,
        SessionEntity::class,
        FpsLogEntity::class,
        TemperatureLogEntity::class,
        NetworkLogEntity::class,
        OptimizationLogEntity::class,
        RollbackLogEntity::class,
        DeviceDnaEntity::class,
        AiRecommendationEntity::class,
        CommunityStatisticEntity::class
    ],
    version = 1,
    exportSchema = false
)
abstract class AgiDatabase : RoomDatabase() {
    abstract fun agiDao(): AgiDao

    companion object {
        @Volatile
        private var INSTANCE: AgiDatabase? = null

        fun getDatabase(context: Context): AgiDatabase {
            return INSTANCE ?: synchronized(this) {
                val instance = Room.databaseBuilder(
                    context.applicationContext,
                    AgiDatabase::class.java,
                    "agi_database"
                )
                .fallbackToDestructiveMigration()
                .build()
                INSTANCE = instance
                instance
            }
        }
    }
}
