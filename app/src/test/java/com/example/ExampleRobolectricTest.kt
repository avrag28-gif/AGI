package com.example

import android.app.Application
import android.content.Context
import androidx.room.Room
import androidx.test.core.app.ApplicationProvider
import com.example.data.database.AgiDatabase
import com.example.data.repository.AgiRepository
import com.example.ui.viewmodel.AgiViewModel
import com.example.ui.viewmodel.TelemetryState
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [36])
class ExampleRobolectricTest {

  private lateinit var db: AgiDatabase
  private lateinit var repository: AgiRepository
  private lateinit var viewModel: AgiViewModel

  @Before
  fun setUp() {
    val context = ApplicationProvider.getApplicationContext<Context>()
    db = Room.inMemoryDatabaseBuilder(context, AgiDatabase::class.java)
        .allowMainThreadQueries()
        .build()
    repository = AgiRepository(db.agiDao())
    viewModel = AgiViewModel(context as Application, repository)
  }

  @After
  fun tearDown() {
    db.close()
  }

  @Test
  fun testDigitalTwinPredictionsUnderNormalConditions() {
    // 1. Siapkan telemetry stabil
    val normalTelemetry = TelemetryState(
        fps = 60,
        cpuUsage = 40,
        gpuUsage = 30,
        ramUsedGb = 3.5f,
        ramTotalGb = 8.0f,
        temperature = 36.5f,
        pingMs = 20
    )

    // 2. Hitung prediksi digital twin
    viewModel.updateDigitalTwinPredictions(normalTelemetry)

    val predictions = viewModel.digitalTwinPredictions.value
    assertEquals(5, predictions.size)

    // Core pinning prediction
    val cpuPinning = predictions.first { it.name == "CPU Core Pinning" }
    assertEquals("3-5% Stabilitas", cpuPinning.fpsChange)
    assertEquals("+0.8°C Panas", cpuPinning.thermalChange)
    assertTrue(cpuPinning.confidence in 70..98)

    // Network Bandwidth prediction
    val netLock = predictions.first { it.name == "Network Bandwidth Lock" }
    assertEquals("-5-10ms Jitter", netLock.fpsChange)
    assertEquals("0% Dampak", netLock.thermalChange)

    // Background Freeze prediction
    val bgFreeze = predictions.first { it.name == "Background Freeze" }
    assertEquals("+200-400MB Bebas RAM", bgFreeze.fpsChange)
  }

  @Test
  fun testDigitalTwinPredictionsUnderExtremeConditions() {
    // 1. Siapkan telemetry panas tinggi, RAM penuh, dan CPU terbebani penuh
    val extremeTelemetry = TelemetryState(
        fps = 45,
        cpuUsage = 92,
        gpuUsage = 85,
        ramUsedGb = 6.8f,
        ramTotalGb = 8.0f,
        temperature = 45.5f,
        pingMs = 120
    )

    // 2. Hitung prediksi digital twin
    viewModel.updateDigitalTwinPredictions(extremeTelemetry)

    val predictions = viewModel.digitalTwinPredictions.value
    assertEquals(5, predictions.size)

    // Core pinning should have higher boost since cpu is heavily loaded
    val cpuPinning = predictions.first { it.name == "CPU Core Pinning" }
    assertEquals("8-12% Stabilitas", cpuPinning.fpsChange)
    assertEquals("+1.4°C Panas", cpuPinning.thermalChange)

    // GPU shading should predict higher boost
    val gpuShading = predictions.first { it.name == "GPU Shading Override" }
    assertEquals("12-16% FPS Rata-rata", gpuShading.fpsChange)

    // Background freeze should free more RAM and cool device more under high loads
    val bgFreeze = predictions.first { it.name == "Background Freeze" }
    assertEquals("+600-900MB Bebas RAM", bgFreeze.fpsChange)

    // Thermal throttle delay should expect high gains under thermal throttle conditions
    val thermalDelay = predictions.first { it.name == "Thermal Throttle Delay" }
    assertEquals("+15-20 FPS (Tahan Throttling)", thermalDelay.fpsChange)
    assertEquals("Sangat Panas (>48°C)", thermalDelay.thermalChange)
  }
}

