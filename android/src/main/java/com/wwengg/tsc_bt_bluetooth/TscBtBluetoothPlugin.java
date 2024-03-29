package com.wwengg.tsc_bt_bluetooth;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.util.Base64;
import android.util.Log;

import androidx.annotation.NonNull;

import com.example.tscdll.TSCActivity;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;

/** TscBtBluetoothPlugin */
public class TscBtBluetoothPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;

  TSCActivity TscDll = new TSCActivity();

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "tsc_bt_bluetooth");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    System.out.println(call.method);
    String res;
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "openPort":
        String address = call.argument("address");
        try {
          System.out.println(address);
          res = TscDll.openport(address);
          System.out.println(res);
          result.success(res);
        }
        catch (Exception e){
          result.error(e.toString(),null,null);
        }
        break;
      case "closePort":
        res = TscDll.closeport();
        result.success(res);
        break;
      case "setup":
        int width = call.argument("width");
        int height = call.argument("height");
        int speed = call.argument("speed");
        int density = call.argument("density");
        int distance = call.argument("distance");
        int offset = call.argument("offset");
//        sensor：0-gap 垂直间距感应器  1-black 黑标感测器
        res = TscDll.setup(width,height,speed,density,0,distance,offset);
        result.success(res);
        break;
      case "clearBuffer":
        res = TscDll.clearbuffer();
        result.success(res);
        break;
      case "printLabel":
        int num = call.argument("num");
        res = TscDll.printlabel(1,num);
        result.success(res);
        break;
      case "printerfont":
        int x = call.argument("x");
        int y = call.argument("y");
        String size = call.argument("size");
        String content = call.argument("content");
        res = TscDll.printerfont(x,y,size,0,1,1,content);
        result.success(res);
        break;
      case "sendBitmapResize":
        int x2 = call.argument("x");
        int y2 = call.argument("y");
        String path = call.argument("path");
        int width2 = call.argument("width");
        int height2 = call.argument("height");
//        Bitmap original_bitmap = null;
        BitmapFactory.Options options = new BitmapFactory.Options();
        options.inPurgeable = true;
        options.inPreferredConfig = Bitmap.Config.ARGB_8888;

        try {
          BitmapFactory.Options.class.getField("inNativeAlloc").setBoolean(options, true);
        } catch (IllegalArgumentException var25) {
          var25.printStackTrace();
        } catch (SecurityException var26) {
          var26.printStackTrace();
        } catch (IllegalAccessException var27) {
          var27.printStackTrace();
        } catch (NoSuchFieldException var28) {
          var28.printStackTrace();
        }
//        InputStream inputStream;
//        try {
//          inputStream = new java.net.URL(path).openStream();
//          original_bitmap = BitmapFactory.decodeStream(inputStream);
//        } catch (IOException e) {
//          e.printStackTrace();
//        }
        byte[] bytes = Base64.decode(path,Base64.DEFAULT);
        Bitmap bitmap = BitmapFactory.decodeByteArray(bytes,0,bytes.length);
        Log.e("sendBitmapResize", path);
        TscDll.sendbitmap_resize(x2,y2,bitmap,width2,height2);
        result.success("1");
      case "sendCommandUTF8":
        String command = call.argument("command");
        res = TscDll.sendcommandUTF8(command);
        result.success(res);
      case "sendCommand":
        String command2 = call.argument("command");
        res = TscDll.sendcommand(command2);
        result.success(res);
      case "sendCommandBIG5":
        String command3 = call.argument("command");
        res = TscDll.sendcommandBig5(command3);
        result.success(res);
      default:
        result.notImplemented();
        break;
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
