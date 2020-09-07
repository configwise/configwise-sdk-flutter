package io.configwise.sdk.cwflutter;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import io.configwise.sdk.domain.ComponentEntity;

class Utils {

    public static final String TAG = Utils.class.getSimpleName();

    public static void checkOnMainThread() throws IllegalStateException {
        if (Thread.currentThread() != Looper.getMainLooper().getThread()) {
            throw new IllegalStateException("This method must be executed from main UI thread");
        }
    }

    public static void runOnUiThread(@NonNull Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }

    public static Map<String, ?> serializeComponentEntity(@NonNull ComponentEntity component) {
        final Map<String, Object> result = new HashMap<>();

        result.put("id", component.getObjectId());
        result.put("genericName", component.getGenericName());
        result.put("description", component.getDescription());
        result.put("productNumber", component.getProductNumber());
        result.put("productLink", component.getProductLink());
        result.put("isFloating", component.isFloating());

        final String thumbnailFileUrl = component.getThumbnailFileUrl();
        result.put("thumbnailFileUrl", thumbnailFileUrl != null ? thumbnailFileUrl : "");

        result.put("totalSize", component.getFilesSize());
        result.put("isVisible", component.isVisible());

        return result;
    }
}