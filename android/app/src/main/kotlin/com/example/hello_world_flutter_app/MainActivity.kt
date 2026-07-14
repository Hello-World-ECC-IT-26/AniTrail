package com.example.hello_world_flutter_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs

class MainActivity : FlutterActivity(), EventChannel.StreamHandler, SensorEventListener {
    private var sensorManager: SensorManager? = null
    private var eventSink: EventChannel.EventSink? = null
    private var rotationVectorSensor: Sensor? = null
    private var accelerometerSensor: Sensor? = null
    private var magnetometerSensor: Sensor? = null
    private var accelerometerValues: FloatArray? = null
    private var magnetometerValues: FloatArray? = null
    private var lastHeading: Float? = null
    private var lastEmitMillis: Long = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "anitrail/device_heading",
        ).setStreamHandler(this)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        val manager = sensorManager ?: return
        rotationVectorSensor = manager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
        accelerometerSensor = manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
        magnetometerSensor = manager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

        val rotationSensor = rotationVectorSensor
        if (rotationSensor != null) {
            manager.registerListener(this, rotationSensor, SensorManager.SENSOR_DELAY_UI)
            return
        }
        accelerometerSensor?.let {
            manager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
        magnetometerSensor?.let {
            manager.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }
    }

    override fun onCancel(arguments: Any?) {
        sensorManager?.unregisterListener(this)
        eventSink = null
        accelerometerValues = null
        magnetometerValues = null
        lastHeading = null
        lastEmitMillis = 0
    }

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                emitHeading(rotationMatrix)
            }
            Sensor.TYPE_ACCELEROMETER -> {
                accelerometerValues = event.values.clone()
                emitHeadingFromFallbackSensors()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magnetometerValues = event.values.clone()
                emitHeadingFromFallbackSensors()
            }
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    private fun emitHeadingFromFallbackSensors() {
        val gravity = accelerometerValues ?: return
        val magnetic = magnetometerValues ?: return
        val rotationMatrix = FloatArray(9)
        val inclinationMatrix = FloatArray(9)
        if (!SensorManager.getRotationMatrix(rotationMatrix, inclinationMatrix, gravity, magnetic)) {
            return
        }
        emitHeading(rotationMatrix)
    }

    private fun emitHeading(rotationMatrix: FloatArray) {
        val adjusted = FloatArray(9)
        val rotation = currentDisplayRotation()
        when (rotation) {
            Surface.ROTATION_90 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_Y,
                SensorManager.AXIS_MINUS_X,
                adjusted,
            )
            Surface.ROTATION_180 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_X,
                SensorManager.AXIS_MINUS_Y,
                adjusted,
            )
            Surface.ROTATION_270 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_Y,
                SensorManager.AXIS_X,
                adjusted,
            )
            else -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_X,
                SensorManager.AXIS_Y,
                adjusted,
            )
        }

        val orientation = FloatArray(3)
        SensorManager.getOrientation(adjusted, orientation)
        val heading = normalizeDegrees(Math.toDegrees(orientation[0].toDouble()).toFloat())
        val now = System.currentTimeMillis()
        val previous = lastHeading
        if (previous != null && abs(shortestDelta(previous, heading)) < 0.5f && now - lastEmitMillis < 120) {
            return
        }
        lastHeading = heading
        lastEmitMillis = now
        eventSink?.success(heading.toDouble())
    }

    private fun currentDisplayRotation(): Int {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation ?: Surface.ROTATION_0
        } else {
            @Suppress("DEPRECATION")
            windowManager.defaultDisplay.rotation
        }
    }

    private fun normalizeDegrees(value: Float): Float {
        val normalized = value % 360f
        return if (normalized < 0f) normalized + 360f else normalized
    }

    private fun shortestDelta(from: Float, to: Float): Float {
        val delta = (to - from + 540f) % 360f - 180f
        return delta
    }
}
