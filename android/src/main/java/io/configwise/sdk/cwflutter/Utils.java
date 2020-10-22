package io.configwise.sdk.cwflutter;

import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import com.google.ar.sceneform.math.Vector3;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.configwise.sdk.domain.AppListItemEntity;
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

    public static void runOnUiThreadDelayed(@NonNull Runnable runnable, long delayMillis) {
        new Handler(Looper.getMainLooper()).postDelayed(runnable, delayMillis);
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

    public static Map<String, ?> serializeAppListItemEntity(@NonNull AppListItemEntity appListItem) {
        final Map<String, Object> result = new HashMap<>();


        result.put("id", appListItem.getObjectId());

        final AppListItemEntity parent = appListItem.getParent();
        result.put("parent_id", parent != null ? parent.getObjectId() : "");

        final ComponentEntity component = appListItem.getComponent();
        result.put("component_id", component != null ? component.getObjectId() : "");

        result.put("type", appListItem.getType().value());
        result.put("label", appListItem.getLabel());
        result.put("description", appListItem.getDescription());

        final String imageUrl = appListItem.getImageUrl();
        result.put("imageUrl", imageUrl != null ? imageUrl : "");

        result.put("index", appListItem.getIndex());
        result.put("textColor", appListItem.getTextColor());

        return result;
    }

    public static List<Double> serialize(@NonNull Vector3 v) {
        List<Double> result = new ArrayList<>();
        result.add((double) v.x);
        result.add((double) v.y);
        result.add((double) v.z);

        return result;
    }

    public static Vector3 deserialize(@NonNull List<Double> arr) {
        return new Vector3(arr.get(0).floatValue(), arr.get(1).floatValue(), arr.get(2).floatValue());
    }
}