package io.configwise.sdk.cwflutter;

import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;
import android.view.MotionEvent;
import android.view.View;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.ar.core.Anchor;
import com.google.ar.core.HitResult;
import com.google.ar.core.Plane;
import com.google.ar.core.Session;
import com.google.ar.sceneform.AnchorNode;
import com.google.ar.sceneform.ArSceneView;
import com.google.ar.sceneform.math.Vector3;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import bolts.Task;
import io.configwise.sdk.ar.ArAdapter;
import io.configwise.sdk.ar.ModelNode;
import io.configwise.sdk.domain.ComponentEntity;
import io.configwise.sdk.services.ComponentService;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

class CwflutterArView implements PlatformView, MethodChannel.MethodCallHandler, ArAdapter.Delegate {

    private static final String TAG = CwflutterArView.class.getSimpleName();

    @NonNull
    private Activity activity;

    @NonNull
    private Context context;

    @NonNull
    private MethodChannel channel;

    @Nullable
    private ArSceneView arSceneView;

    @Nullable
    private ArAdapter arAdapter;

    @NonNull
    private final Application.ActivityLifecycleCallbacks activityLifecycleCallback = new Application.ActivityLifecycleCallbacks() {
        @Override
        public void onActivityCreated(@NonNull Activity activity, @Nullable Bundle savedInstanceState) {
        }

        @Override
        public void onActivityStarted(@NonNull Activity activity) {
        }

        @Override
        public void onActivityResumed(@NonNull Activity activity) {
            startArSession();
        }

        @Override
        public void onActivityPaused(@NonNull Activity activity) {
            stopArSession();
        }

        @Override
        public void onActivityStopped(@NonNull Activity activity) {
            stopArSession();
        }

        @Override
        public void onActivitySaveInstanceState(@NonNull Activity activity, @NonNull Bundle outState) {
        }

        @Override
        public void onActivityDestroyed(@NonNull Activity activity) {
            destroyArSession();
        }
    };

    public CwflutterArView(@NonNull Activity activity, @NonNull Context context, @NonNull BinaryMessenger messenger, int viewId) {
        this.activity = activity;
        this.context = context;

        channel = new MethodChannel(messenger, CwflutterPlugin.VIEW_FACTORY_ID + "_" + viewId);
        channel.setMethodCallHandler(this);

        arSceneView = new ArSceneView(context);

        // Setup ArAdapter
        arAdapter = new ArAdapter(
                activity,
                context,
                arSceneView,
                null
        );
        arAdapter.setDelegate(this);

        activity.getApplication().registerActivityLifecycleCallbacks(activityLifecycleCallback);
    }

    // MARK: - PlatformView

    @Override
    public View getView() {
        return arSceneView;
    }

    @Override
    public void dispose() {
        destroyArSession();
        activity.getApplication().unregisterActivityLifecycleCallbacks(activityLifecycleCallback);
    }

    // MARK: - MethodCallHandler

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        final Map<String, ?> args = call.arguments();

        if (call.method.equals("init")) {
            startArSession();
            result.success(null);
        }

        else if (call.method.equals("dispose")) {
            // TODO [smuravev] Validate if we need call dispose() here.
            //                 Maybe it's unnecessary because Android PlatformView already has (see above):
            //                 @Override public void dispose() { . . . }
            //                 which executed automatically - so to avoid double call of this method,
            //                 we must ignore dispose() call here.
//            dispose();
            result.success(null);
        }

        else if (call.method.equals("addModel")) {
            String componentId = (String) args.get("componentId");
            if (componentId == null || componentId.isEmpty()) {
                result.error(
                        CwflutterPlugin.BAD_REQUEST,
                        "'componentId' parameter must not be blank.",
                        null
                );
                return;
            }

            final List<Double> argWorldPosition = (List<Double>) args.get("worldPosition");
            Vector3 worldPosition = null;
            if (argWorldPosition != null && !argWorldPosition.isEmpty()) {
                worldPosition = Utils.deserialize(argWorldPosition);
            }

            addModel(componentId, worldPosition).continueWith(task -> {
                if (task.isCancelled()) {
                    result.error(
                            CwflutterPlugin.INTERNAL_ERROR,
                            "Unable to add model due invocation task is canceled.",
                            null
                    );
                    return null;
                }

                if (task.isFaulted()) {
                    Exception e = task.getError();
                    result.error(
                            CwflutterPlugin.INTERNAL_ERROR,
                            e.getMessage(),
                            null
                    );
                    return null;
                }

                result.success(null);
                return null;
            }, Task.UI_THREAD_EXECUTOR);
        }

        if (call.method.equals("resetSelection")) {
            ModelNode selectedModel = arAdapter.getSelectedModel();
            if (selectedModel != null) {
                selectedModel.deselect();
            }
            result.success(null);
        }

        if (call.method.equals("removeSelectedModel")) {
            ModelNode selectedModel = arAdapter.getSelectedModel();
            if (selectedModel != null) {
                arAdapter.removeModel(selectedModel);
            }
            result.success(null);
        }

        if (call.method.equals("removeModel")) {
            String modelId = (String) args.get("modelId");
            if (modelId == null || modelId.isEmpty()) {
                result.error(
                        CwflutterPlugin.BAD_REQUEST,
                        "'modelId' parameter must not be blank.",
                        null
                );
                return;
            }
            for(ModelNode model : arAdapter.getModels()) {
                if (modelId.equals(model.getId())) {
                    arAdapter.removeModel(model);
                }
            }
            result.success(null);
        }

        else {
            result.notImplemented();
        }
    }

    // MARK: - Models

    private Task<Boolean> addModel(@NonNull String componentId, @Nullable Vector3 worldPosition) {
        return ComponentService.getInstance().obtainComponentById(componentId)
                .onSuccessTask(task -> {
                    final ComponentEntity component = task.getResult();
                    if (component == null) {
                        return Task.forResult(false);
                    }
                    if (arAdapter == null) {
                        return Task.forResult(false);
                    }

                    arAdapter.addModel(
                            component,
                            null,
                            worldPosition,
                            null,
                            null,
                            true
                    );

                    return Task.forResult(true);
                }, Task.UI_THREAD_EXECUTOR);
    }

    // MARK: - AR

    private void startArSession() {
        if (arAdapter != null) {
            arAdapter.startArSession();
            Utils.runOnUiThread(() -> {
                channel.invokeMethod("onArSessionStarted", false);
            });
        }
    }

    private void stopArSession() {
        if (arAdapter != null) {
            arAdapter.stopArSession();
            Utils.runOnUiThread(() -> {
                channel.invokeMethod("onArSessionPaused", null);
            });
        }
    }

    private void destroyArSession() {
        if (arAdapter != null) {
            arAdapter.destroyArSession();
        }
        arSceneView = null;
        arAdapter = null;
    }

    @Override
    public void onArSessionInitialized(Session session) {
        if (arAdapter != null) {
            arAdapter.setSelectionVisualizerType(ArAdapter.SelectionVisualizerType.JUMPING);
        }

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onArShowHelpMessage", "Point your phone against the floor at an angle.");
        });
    }

    @Override
    public void onArError(@NonNull Throwable throwable) {
        final Map<String, Object> args = new HashMap<>();
        args.put("isCritical", false);
        args.put("message", throwable.getMessage());

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onError", args);
        });
    }

    @Override
    public void onArCriticalError(@NonNull Throwable tr) {
        final Map<String, Object> args = new HashMap<>();
        args.put("isCritical", true);
        args.put("message", tr.getMessage());

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onError", args);
        });
    }

    @Override
    public void onPlaneDetected(@NonNull Plane plane, @NonNull Anchor anchor) {
        if (arAdapter != null) {
            arAdapter.disablePlaneDiscoveryInstruction();

            // Attach a node to the anchor with the scene as the parent
            final AnchorNode anchorNode = new AnchorNode(anchor);
            anchorNode.setParent(arAdapter.getArSceneView().getScene());

            Utils.runOnUiThread(() -> {
                channel.invokeMethod("onArPlaneDetected", Utils.serialize(anchorNode.getWorldPosition()));
            });
        }
    }

    @Override
    public void onPlaneTapped(@NonNull HitResult hitResult, @NonNull Plane plane, @NonNull MotionEvent motionEvent) {
    }

    @Override
    public void onPlaneDiscoveryInstructionShown() {
    }

    @Override
    public void onPlaneDiscoveryInstructionHidden() {
    }

    @Override
    public void onModelAdded(@NonNull ModelNode model) {
        final Map<String, Object> args = new HashMap<>();
        args.put("modelId", model.getId());
        args.put("componentId", model.getComponent().getObjectId());

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onArModelAdded", args);
            channel.invokeMethod("onArShowHelpMessage", "Use gestures to move & rotate object. Tap on it to select. Tap on empty space to deselect object.");
        });
    }

    @Override
    public void onModelDeleted(@NonNull ModelNode model) {
        final Map<String, Object> args = new HashMap<>();
        args.put("modelId", model.getId());
        args.put("componentId", model.getComponent().getObjectId());

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onModelDeleted", args);
        });
    }

    @Override
    public void onModelSelected(@NonNull ModelNode model) {
        final Map<String, Object> args = new HashMap<>();
        args.put("modelId", model.getId());
        args.put("componentId", model.getComponent().getObjectId());

        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onModelSelected", args);
        });
    }

    @Override
    public void onModelDeselected(@NonNull ModelNode model) {
        Utils.runOnUiThread(() -> {
            channel.invokeMethod("onSelectionReset", null);
        });
    }

    @Override
    public void onModelLoadingStarted(@NonNull ModelNode model) {
    }

    @Override
    public void onModelLoadingFinished(@NonNull ModelNode model, @Nullable Exception e, boolean cancelled, boolean completed) {
        if (e != null) {
            Log.e(TAG, "Unable to load model due error", e);
            onArError(e);
            return;
        }

        if (cancelled) {
            onArError(new RuntimeException("Loading of model is canceled"));
            return;
        }

        if (!completed) {
            onArError(new RuntimeException("Loading of model has not been completed"));
            return;
        }
    }
}