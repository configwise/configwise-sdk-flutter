package io.configwise.sdk.cwflutter;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class ArFactory extends PlatformViewFactory {

    private static final String TAG = ArFactory.class.getSimpleName();

    @NonNull
    private Activity activity;

    @NonNull
    private BinaryMessenger messenger;

    public ArFactory(@NonNull Activity activity, @NonNull BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        return new CwflutterArView(activity, context, messenger, viewId);
    }
}