package com.cleverpush.flutter;

import android.app.Activity;

import java.util.HashMap;

import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

abstract class FlutterRegistrarResponder {
   MethodChannel channel;
   PluginRegistry.Registrar flutterRegistrar;

   void replySuccess(final MethodChannel.Result reply, final Object response) {
      runOnMainThread(new Runnable() {
         @Override
         public void run() {
            reply.success(response);
         }
      });
   }

   void replyError(final MethodChannel.Result reply, final String tag, final String message, final Object response) {
      runOnMainThread(new Runnable() {
         @Override
         public void run() {
            reply.error(tag, message, response);
         }
      });
   }

   void replyNotImplemented(final MethodChannel.Result reply) {
      runOnMainThread(new Runnable() {
         @Override
         public void run() {
            reply.notImplemented();
         }
      });
   }

   private void runOnMainThread(final Runnable runnable) {
      ((Activity) flutterRegistrar.activeContext()).runOnUiThread(runnable);
   }

   void invokeMethodOnUiThread(final String methodName, final HashMap map) {
      final MethodChannel channel = this.channel;
      runOnMainThread(new Runnable() {
         @Override
         public void run() {
            channel.invokeMethod(methodName, map);
         }
      });
   }
}
