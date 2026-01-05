package com.example.mult_media_picker

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.ThumbnailUtils
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream


/** MultMediaPickerPlugin */
class MultMediaPickerPlugin: FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel
  private lateinit var context : Context

  private var activity: Activity? = null
  private var maxCount: Int = 9
  private var mediaType: Int? = null
  private var pendingResult: MethodChannel.Result? = null


  companion object {
    private const val REQUEST_CODE_PICK = 2001
  }

  override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "mult_media_picker")
    channel.setMethodCallHandler(this)
    context = flutterPluginBinding.applicationContext
  }

  override fun onMethodCall(call: MethodCall, result: Result) {
   if (call.method == "pickMedia") {
        maxCount = call.argument<Int>("maxCount") ?:0
        mediaType = call.argument<Int>("mediaType")
        val isSingle = call.argument<Boolean>("isSingle") ?:false
        pendingResult = result
        launchPhotoPicker(isSingle)
    } else if (call.method == "getThumbnail") {
        val path = call.argument<String>("path") ?: ""
        val type = call.argument<Int>("mediaType") ?: 0
        Thread{ result.success(getThumbnail(path,type))}.start()
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
     activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
    binding.addActivityResultListener(this)
  }

  override fun onDetachedFromActivity() {
    activity = null
  }


  private fun launchPhotoPicker(isSingle: Boolean) {
    val activity = this.activity ?: run {
        pendingResult?.error("NO_ACTIVITY", "Activity not available", null)
        return
    }
    val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
      // Android 13+ 使用新 Photo Picker（无需权限）
      Intent(MediaStore.ACTION_PICK_IMAGES).apply {
        if (!isSingle) {
          putExtra(MediaStore.EXTRA_PICK_IMAGES_MAX, maxCount)
        }
        type = when(mediaType) {
          0 -> "image/*"
          1 -> "video/*"
          else -> "*/*"
        }
      }
    } else {
      // Android 12及以下使用ACTION_GET_CONTENT(无需权限)
      Intent(Intent.ACTION_GET_CONTENT).apply {
        type = when (mediaType) {
          0 -> "image/*"
          1 -> "video/*"
          else -> "*/*"
        }
        addCategory(Intent.CATEGORY_OPENABLE)
        if (!isSingle) {
          putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
        }
      }
    }
    activity.startActivityForResult(intent, REQUEST_CODE_PICK)
  }

  private fun getThumbnail(path: String, media: Int) : ByteArray? {
     return  try {
         val bitmap = if (mediaType == 1) {
           if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
             ThumbnailUtils.createVideoThumbnail(File(path), Size(300, 300), null)
           } else {
             ThumbnailUtils.createVideoThumbnail(path, MediaStore.Images.Thumbnails.MINI_KIND)
           }
         } else {
           val options = BitmapFactory.Options().apply { inSampleSize = 4 }
           BitmapFactory.decodeFile(path, options)
         }
       bitmap?.let {
         val stream = ByteArrayOutputStream()
         it.compress(Bitmap.CompressFormat.JPEG, 80, stream)
         stream.toByteArray()
       }
     } catch (e: Exception) {
       null
     }
  }

  private fun processUri(uri: Uri) : Map<String, Any>? {
    return  try {
      // copy to cache for access
      val fileName = "picked_${System.currentTimeMillis()}_${uri.lastPathSegment?.replace("/", "_") ?: "file"}"
      val cacheFile = File(context.cacheDir, fileName)

      context.contentResolver.openInputStream(uri).use { input ->
        FileOutputStream(cacheFile).use { outPut ->
          input?.copyTo(outPut)
        }
      }
      val isVideo = context.contentResolver.getType(uri)?.startsWith("video") == true
      mapOf(
        "path" to cacheFile.absolutePath,
        "mediaType" to if (isVideo) 1 else 0,
        "dateCreate" to (System.currentTimeMillis() / 1000).toInt(),
      )
    } catch (e: Exception) {
      null
    }
  }

  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
    if (requestCode != REQUEST_CODE_PICK) return  false

    if (resultCode != Activity.RESULT_OK || data == null) {
      pendingResult?.success(emptyList<Map<String, Any>>())
      pendingResult = null
      return true
    }

    Thread {
      val results = mutableListOf<Map<String, Any>>()
      // handle nutiple selection
      val clipData = data.clipData
      if (clipData != null) {
        for (i in 0 until clipData.itemCount) {
          val uri = clipData.getItemAt(i).uri
          processUri(uri)?.let { results.add(it) }
        }
      } else {
        // Single selection
        data.data?.let { uri ->
          processUri(uri)?.let { results.add(it) }
        }
      }

      activity?.runOnUiThread {
        pendingResult?.success(results)
        pendingResult = null
      }
    }.start()
    return true
  }


}
