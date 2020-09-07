package io.configwise.sdk.cwflutter;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.ar.core.exceptions.CameraNotAvailableException;
import com.google.ar.sceneform.ArSceneView;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

class CwflutterArView implements PlatformView, MethodChannel.MethodCallHandler {

    private static final String TAG = CwflutterArView.class.getSimpleName();

    @NonNull
    private Activity activity;

    @NonNull
    private Context context;

    @NonNull
    private MethodChannel channel;

    @Nullable
    private ArSceneView arSceneView;

    public CwflutterArView(@NonNull Activity activity, @NonNull Context context, @NonNull BinaryMessenger messenger, int viewId) {
        this.activity = activity;
        this.context = context;

        channel = new MethodChannel(messenger, CwflutterPlugin.VIEW_FACTORY_ID + "_" + viewId);
        channel.setMethodCallHandler(this);

        arSceneView = new ArSceneView(context);

//        ArCoreUtils.requestCameraPermission(activity, RC_PERMISSIONS);

        setupLifeCycle(context);
    }

    private void setupLifeCycle(Context context) {
        activity.getApplication().registerActivityLifecycleCallbacks(new Application.ActivityLifecycleCallbacks() {
            @Override
            public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
            }

            @Override
            public void onActivityStarted(@NonNull Activity activity) {
            }

            @Override
            public void onActivityResumed(@NonNull Activity activity) {
                onResume();
            }

            @Override
            public void onActivityPaused(@NonNull Activity activity) {
                onPause();
            }

            @Override
            public void onActivityStopped(@NonNull Activity activity) {
                onPause();
            }

            @Override
            public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {
            }

            @Override
            public void onActivityDestroyed(@NonNull Activity activity) {
                onDestroy();
            }
        });
    }

    // MARK: - ActivityLifecycle

    private void onResume() {
        if (arSceneView == null) {
            return;
        }

        // request camera permission if not already requested
//        if (!ArCoreUtils.hasCameraPermission(activity)) {
//            ArCoreUtils.requestCameraPermission(activity, RC_PERMISSIONS)
//        }

        try {
            arSceneView.resume();
        } catch (CameraNotAvailableException e) {
            Log.e(TAG, "Unable to resume AR session due error", e);
            activity.finish();
        }
    }

    private void onPause() {
        if (arSceneView != null) {
            arSceneView.pause();
        }
    }

    private void onDestroy() {
        if (arSceneView != null) {
            arSceneView.destroy();
            arSceneView = null;
        }
    }

    // MARK: - PlatformView

    @Override
    public View getView() {
        return arSceneView;
    }

    @Override
    public void dispose() {
        if (arSceneView != null) {
            onPause();
            onDestroy();
        }
    }

    // MARK: - MethodCallHandler

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        // TODO [smuravev] Implement CwflutterArView.onMethodCall()
    }
}