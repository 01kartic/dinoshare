package com.example.dinoshare

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.ParcelFileDescriptor
import android.provider.OpenableColumns
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "dinoshare/picker"
        private const val PICK_CODE = 0x4C61  // "La"
    }

    private var pendingResult: MethodChannel.Result? = null

    // Keeps ParcelFileDescriptors alive until the next pick session starts.
    // Each PFD must stay open until Dart has had a chance to open the
    // /proc/self/fd/{n} path; after that the Dart RandomAccessFile holds
    // its own fd and the original PFD is no longer needed.
    private val openPfds = mutableListOf<ParcelFileDescriptor>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> launchPicker(result)
                    "readUriBytes" -> readUriBytes(call.argument<String>("uri"), result)
                    "openUri" -> openUri(call.argument<String>("uri"), result)
                    "closeAll" -> { closeAll(); result.success(null) }
                    else -> result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun launchPicker(result: MethodChannel.Result) {
        if (pendingResult != null) { result.success(null); return }
        pendingResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
        }
        startActivityForResult(intent, PICK_CODE)
    }

    @Suppress("DEPRECATION", "OVERRIDE_DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_CODE) return
        val result = pendingResult ?: return
        pendingResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result.success(null)
            return
        }

        val uris = mutableListOf<Uri>()
        data.clipData?.let { clip ->
            for (i in 0 until clip.itemCount) uris.add(clip.getItemAt(i).uri)
        } ?: data.data?.let { uris.add(it) }

        val files = mutableListOf<Map<String, Any?>>()
        for (uri in uris) {
            try {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                } catch (_: Exception) { }
                val pfd = contentResolver.openFileDescriptor(uri, "r") ?: continue
                openPfds.add(pfd)
                val (name, size) = queryMeta(uri)
                files.add(mapOf(
                    "path" to "/proc/self/fd/${pfd.fd}",
                    "uri" to uri.toString(),
                    "name" to name,
                    "size" to size,
                ))
            } catch (_: Exception) { }
        }
        result.success(files)
    }

    private fun queryMeta(uri: Uri): Pair<String, Long> {
        var name = uri.lastPathSegment ?: "file"
        var size = 0L
        try {
            contentResolver.query(
                uri,
                arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE),
                null, null, null,
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    name = cursor.getString(0) ?: name
                    size = cursor.getLong(1)
                }
            }
        } catch (_: Exception) { }
        return name to size
    }

    private fun closeAll() {
        openPfds.forEach { try { it.close() } catch (_: Exception) { } }
        openPfds.clear()
    }

    private fun readUriBytes(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrBlank()) {
            result.success(null)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            contentResolver.openInputStream(uri)?.use { input ->
                result.success(input.readBytes())
            } ?: result.success(null)
        } catch (e: Exception) {
            result.error("read_failed", e.message, null)
        }
    }

    private fun openUri(uriString: String?, result: MethodChannel.Result) {
        if (uriString.isNullOrBlank()) {
            result.success(false)
            return
        }
        try {
            val uri = Uri.parse(uriString)
            val mime = contentResolver.getType(uri) ?: "*/*"
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, mime)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            startActivity(Intent.createChooser(intent, null))
            result.success(true)
        } catch (e: Exception) {
            result.error("open_failed", e.message, null)
        }
    }
}
