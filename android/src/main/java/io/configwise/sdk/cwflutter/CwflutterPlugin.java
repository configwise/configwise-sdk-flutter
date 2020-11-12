package io.configwise.sdk.cwflutter;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import org.greenrobot.eventbus.EventBus;
import org.greenrobot.eventbus.Subscribe;
import org.greenrobot.eventbus.ThreadMode;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import bolts.Task;
import io.configwise.sdk.ConfigWiseSDK;

import io.configwise.sdk.domain.AppListItemEntity;
import io.configwise.sdk.domain.CompanyEntity;
import io.configwise.sdk.domain.ComponentEntity;
import io.configwise.sdk.domain.UserEntity;
import io.configwise.sdk.eventbus.SignOutEvent;
import io.configwise.sdk.eventbus.UnsupportedAppVersionEvent;
import io.configwise.sdk.services.AppListItemService;
import io.configwise.sdk.services.AuthService;
import io.configwise.sdk.services.CompanyService;
import io.configwise.sdk.services.ComponentService;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;


/**
 * CwflutterPlugin
 */
public class CwflutterPlugin implements FlutterPlugin, ActivityAware, MethodCallHandler {

    private static final String TAG = CwflutterPlugin.class.getSimpleName();

    private static final String CHANNEL_NAME = "cwflutter";

    static final String VIEW_FACTORY_ID = "cwflutter_ar";

    public static final String BAD_REQUEST = "400";
    public static final String UNAUTHORIZED = "401";
    public static final String FORBIDDEN = "403";
    public static final String NOT_FOUND = "404";
    public static final String INTERNAL_ERROR = "500";
    public static final String NOT_IMPLEMENTED = "501";

    @Nullable
    private FlutterPluginBinding flutterPluginBinding;

    @Nullable
    private MethodChannel channel;

    @Nullable
    private Activity activity;

    private void startListening(BinaryMessenger messenger) {
        channel = new MethodChannel(messenger, CHANNEL_NAME);
        channel.setMethodCallHandler(this);
    }

    // This static function is optional and equivalent to onAttachedToEngine. It supports the old
    // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
    // plugin registration via this function while apps migrate to use the new Android APIs
    // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
    //
    // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
    // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
    // depending on the user's project. onAttachedToEngine or registerWith must both be defined
    // in the same class.
    public static void registerWith(Registrar registrar) {
        CwflutterPlugin plugin = new CwflutterPlugin();
        plugin.startListening(registrar.messenger());

        registrar
                .platformViewRegistry()
                .registerViewFactory(
                        VIEW_FACTORY_ID,
                        new ArFactory(registrar.activity(), registrar.messenger())
                );
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        flutterPluginBinding = binding;
        startListening(binding.getBinaryMessenger());
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
        channel = null;
        flutterPluginBinding = null;
    }

    // MARK: - ActivityAware

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        this.activity = binding.getActivity();

        if (flutterPluginBinding != null) {
            flutterPluginBinding.getPlatformViewRegistry()
                    .registerViewFactory(
                            VIEW_FACTORY_ID,
                            new ArFactory(this.activity, flutterPluginBinding.getBinaryMessenger())
                    );
        }

        EventBus.getDefault().register(this);
    }

    @Override
    public void onDetachedFromActivity() {
        EventBus.getDefault().unregister(this);
        this.activity = null;
    }

    @Override
    public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
        onAttachedToActivity(binding);
    }

    @Override
    public void onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity();
    }

    // MARK: - MethodCallHandler

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        final Map<String, ?> args = call.arguments();

        if (call.method.equals("getPlatformVersion")) {
            result.success("Android " + android.os.Build.VERSION.RELEASE);
        } else if (call.method.equals("checkConfiguration")) {
            boolean res = checkConfiguration(args);
            result.success(res);
        } else if (call.method.equals("initialize")) {
            if (this.activity == null) {
                result.error(
                        INTERNAL_ERROR,
                        "Invalid state of ConfigWise Flutter plugin (activity is null).",
                        null
                );
                return;
            }

            String companyAuthToken = (String) args.get("companyAuthToken");
            if (companyAuthToken == null || companyAuthToken.isEmpty()) {
                result.error(
                        BAD_REQUEST,
                        "'companyAuthToken' parameter must not be blank.",
                        null
                );
                return;
            }

            ConfigWiseSDK.initialize(new ConfigWiseSDK.Builder(this.activity.getApplicationContext())
                    .sdkVariant(ConfigWiseSDK.SdkVariant.B2C)
                    .companyAuthToken(companyAuthToken)
                    .debugLogging(false)
                    .debug3d(false)
            );

            result.success(true);
        } else if (call.method.equals("signIn")) {
            signIn().continueWith(task -> {
                if (task.isCancelled()) {
                    String message = "Unable to sign in due invocation task is canceled.";
                    Log.e(TAG, message);
                    result.error(
                            UNAUTHORIZED,
                            message,
                            null
                    );
                    return null;
                }

                if (task.isFaulted()) {
                    Exception e = task.getError();
                    Log.e(TAG, "Unable to sign in due error", e);
                    result.error(
                            UNAUTHORIZED,
                            e.getMessage(),
                            null
                    );
                    return null;
                }

                result.success(task.getResult());
                return null;
            }, Task.UI_THREAD_EXECUTOR);
        } else if (call.method.equals("obtainAllComponents")) {
            Integer offset = (Integer) args.get("offset");
            Integer max = (Integer) args.get("max");

            obtainAllComponents(offset, max).continueWith(task -> {
                if (task.isCancelled()) {
                    String message = "Unable to obtain components due invocation task is canceled.";
                    Log.e(TAG, message);
                    result.error(
                            INTERNAL_ERROR,
                            message,
                            null
                    );
                    return null;
                }

                if (task.isFaulted()) {
                    Exception e = task.getError();
                    Log.e(TAG, "Unable to obtain components due error", e);
                    result.error(
                            INTERNAL_ERROR,
                            e.getMessage(),
                            null
                    );
                    return null;
                }

                result.success(task.getResult());
                return null;
            }, Task.UI_THREAD_EXECUTOR);
        } else if (call.method.equals("obtainComponentById")) {
            String componentId = (String) args.get("id");
            if (componentId == null || componentId.isEmpty()) {
                result.error(
                        BAD_REQUEST,
                        "'componentId' parameter must not be blank.",
                        null
                );
                return;
            }

            obtainComponentById(componentId).continueWith(task -> {
                if (task.isCancelled()) {
                    String message = "Unable to obtain component due invocation task is canceled.";
                    Log.e(TAG, message);
                    result.error(
                            INTERNAL_ERROR,
                            message,
                            null
                    );
                    return null;
                }

                if (task.isFaulted()) {
                    Exception e = task.getError();
                    Log.e(TAG, "Unable to obtain component due error", e);
                    result.error(
                            INTERNAL_ERROR,
                            e.getMessage(),
                            null
                    );
                    return null;
                }

                result.success(task.getResult());
                return null;
            }, Task.UI_THREAD_EXECUTOR);
        } else if (call.method.equals("obtainAllAppListItems")) {
            String parentId = (String) args.get("parent_id");
            Integer offset = (Integer) args.get("offset");
            Integer max = (Integer) args.get("max");

            obtainAllAppListItems(parentId, offset, max).continueWith(task -> {
                if (task.isCancelled()) {
                    String message = "Unable to obtain appListItems due invocation task is canceled.";
                    Log.e(TAG, message);
                    result.error(
                            INTERNAL_ERROR,
                            message,
                            null
                    );
                    return null;
                }

                if (task.isFaulted()) {
                    Exception e = task.getError();
                    Log.e(TAG, "Unable to obtain appListItems due error", e);
                    result.error(
                            INTERNAL_ERROR,
                            e.getMessage(),
                            null
                    );
                    return null;
                }

                result.success(task.getResult());
                return null;
            }, Task.UI_THREAD_EXECUTOR);
        } else {
            result.notImplemented();
        }
    }

    @Subscribe(threadMode = ThreadMode.MAIN_ORDERED)
    public void onEventSignOut(SignOutEvent event) {
        Utils.runOnUiThread(() -> {
            if (channel != null) {
                channel.invokeMethod("onSignOut", "Unauthorized.");
            }
        });
    }

    @Subscribe(threadMode = ThreadMode.MAIN_ORDERED)
    public void onEventUnsupportedAppVersion(UnsupportedAppVersionEvent event) {
        String message = "Unsupported ConfigWiseSDK version. Please update it.";
        Log.e(TAG, message);
        Utils.runOnUiThread(() -> {
            if (channel != null) {
                channel.invokeMethod("onSignOut", message);
            }
        });
    }

    private boolean checkConfiguration(Map<String, ?> args) {
        if (this.activity == null) {
            return false;
        }

        Integer configurationType = (Integer) args.get("configuration");
        if (configurationType == null) {
            return false;
        }

        boolean res = false;
        switch (configurationType) {
            case 0: // ARWorldTracking
                res = io.configwise.sdk.Utils.isArCompatible(this.activity.getApplicationContext());
                break;

            case 1: // ARImageTracking
                // TODO [smuravev] Implement detection if ARCore (running on the current device) supports ARImageTracking
                break;

            case 2: // ARFaceTracking
                // TODO [smuravev] Implement detection if ARCore (running on the current device) supports ARFaceTracking
                break;

            case 3: // ARBodyTracking
                // TODO [smuravev] Implement detection if ARCore (running on the current device) supports ARBodyTracking
                break;

            default:
                break;
        }

        return res;
    }

    private Task<Boolean> signIn() {
        return CompanyService.getInstance().obtainCurrentCompany()
                .onSuccessTask(obtainCurrentCompanyTask -> {
                    CompanyEntity company = obtainCurrentCompanyTask.getResult();
                    if (company != null) {
                        return Task.forResult(true);
                    }

                    return AuthService.getInstance().signIn(
                            ConfigWiseSDK.getInstance().getCompanyAuthToken(),
                            ConfigWiseSDK.getInstance().getCompanyAuthToken()
                    )
                            .onSuccessTask(signInTask -> {
                                UserEntity user = signInTask.getResult();
                                if (user != null) {
                                    return Task.forResult(true);
                                }

                                throw new RuntimeException("Unauthorized - user not found.");
                            });
                });
    }

    private Task<List<Map<String, ?>>> obtainAllComponents(@Nullable Integer offset, @Nullable Integer max) {
        return ComponentService.getInstance().obtainAllComponentsByCurrentCatalog(offset, max)
                .onSuccessTask(task -> {
                    List<Map<String, ?>> result = new ArrayList<>();

                    List<ComponentEntity> entities = task.getResult();
                    for (ComponentEntity it : entities) {
                        if (it.isVisible()) {
                            result.add(Utils.serializeComponentEntity(it));
                        }
                    }

                    return Task.forResult(result);
                });
    }

    private Task<Map<String, ?>> obtainComponentById(@NonNull String componentId) {
        return ComponentService.getInstance().obtainComponentById(componentId)
                .onSuccessTask(task -> {
                    ComponentEntity component = task.getResult();

                    return Task.forResult(component != null
                            ? Utils.serializeComponentEntity(component)
                            : null
                    );
                });
    }

    private Task<List<Map<String, ?>>> obtainAllAppListItems(@Nullable String parentId, @Nullable Integer offset, @Nullable Integer max) {
        AppListItemEntity parent = null;
        if (parentId != null && !parentId.isEmpty()) {
            parent = new AppListItemEntity();
            parent.setObjectId(parentId);
        }

        return AppListItemService.getInstance().obtainAllAppListItemsByCurrentCatalogAndParent(parent, offset, max)
                .onSuccessTask(task -> {
                    List<Map<String, ?>> result = new ArrayList<>();

                    List<AppListItemEntity> entities = task.getResult();
                    for (AppListItemEntity it : entities) {
                        if (isAppListItemVisible(it)) {
                            result.add(Utils.serializeAppListItemEntity(it));
                        }
                    }

                    return Task.forResult(result);
                });
    }

    private boolean isAppListItemVisible(@NonNull AppListItemEntity entity) {
        if (!entity.isEnabled()) {
            return false;
        }

        if (entity.isOverlayImage()) {
            return entity.isImageExist()
                    || !entity.getLabel().isEmpty()
                    || !entity.getDescription().isEmpty();
        }
        else if (entity.isNavigationItem()) {
            return !entity.getLabel().isEmpty() || !entity.getDescription().isEmpty();
        }
        else if (entity.isMainProduct()) {
            final ComponentEntity component = entity.getComponent();
            if (component == null) {
                return false;
            }

            return component.isVisible();
        }

        return false;
    }
}
