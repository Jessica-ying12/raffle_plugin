/**
 * Raffle插件的Android原生实现
 * 提供抽奖相关的原生功能，包括：
 * - 获取平台版本
 * - 播放抽奖音效
 * - 触发设备震动
 * - 保存抽奖结果
 * - 获取抽奖历史记录
 */
package com.giselle.raffle;

// Android核心库导入
import androidx.annotation.NonNull;
import android.content.Context;
import android.content.SharedPreferences; // 用于本地数据存储
import android.media.MediaPlayer; // 用于音频播放
import android.os.Vibrator; // 用于设备震动
import android.os.VibrationEffect; // 用于Android O及以上版本的震动效果
import android.os.Build; // 用于检查Android版本
import android.util.Log; // 用于日志记录

// Flutter插件相关导入
import io.flutter.embedding.engine.plugins.FlutterPlugin; // Flutter插件接口
import io.flutter.plugin.common.MethodCall; // 方法调用
import io.flutter.plugin.common.MethodChannel; // 方法通道
import io.flutter.plugin.common.MethodChannel.MethodCallHandler; // 方法调用处理器
import io.flutter.plugin.common.MethodChannel.Result; // 方法调用结果

// Java工具类导入
import java.util.List; // 列表接口
import java.util.ArrayList; // 数组列表实现
import java.util.Map; // 映射接口
import java.util.HashMap; // 哈希映射实现
import java.util.Set; // 集合接口
import java.util.HashSet; // 哈希集合实现

// JSON处理相关导入
import com.google.gson.Gson; // Google的JSON处理库
import com.google.gson.reflect.TypeToken; // 用于泛型类型转换
import java.lang.reflect.Type; // 反射类型

/** 
 * Raffle插件主类
 * 实现Flutter插件接口和方法调用处理器接口
 * 负责处理来自Flutter端的方法调用并提供原生功能
 */
public class RafflePlugin implements FlutterPlugin, MethodCallHandler {
  // 常量定义
  private static final String TAG = "RafflePlugin"; // 日志标签
  private static final String PREFS_NAME = "raffle_prefs"; // SharedPreferences名称
  private static final String HISTORY_KEY = "raffle_history"; // 历史记录键名
  
  // 成员变量
  private MethodChannel channel; // 与Flutter通信的方法通道
  private Context context; // 应用上下文
  private Vibrator vibrator; // 震动服务
  private SharedPreferences prefs; // 本地存储
  private Gson gson; // JSON处理器

  /**
   * 插件附加到Flutter引擎时调用
   * 初始化方法通道和各种服务
   * @param flutterPluginBinding Flutter插件绑定对象
   */
  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    // 创建方法通道，通道名称为"raffle"，与Flutter端保持一致
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "raffle");
    // 设置方法调用处理器为当前类实例
    channel.setMethodCallHandler(this);
    // 获取应用上下文
    context = flutterPluginBinding.getApplicationContext();
    // 获取震动服务
    vibrator = (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
    // 初始化SharedPreferences
    prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    // 初始化Gson
    gson = new Gson();
  }

  /**
   * 处理来自Flutter的方法调用
   * 根据方法名分发到对应的处理函数
   * @param call 方法调用对象，包含方法名和参数
   * @param result 结果回调，用于向Flutter返回结果
   */
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case "getPlatformVersion":
        // 返回Android平台版本
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
      case "playRaffleSound":
        // 播放抽奖音效
        playRaffleSound(call, result);
        break;
      case "triggerVibration":
        // 触发设备震动
        triggerVibration(call, result);
        break;
      case "saveRaffleResult":
        // 保存抽奖结果
        saveRaffleResult(call, result);
        break;
      case "getRaffleHistory":
        // 获取抽奖历史记录
        getRaffleHistory(result);
        break;
      default:
        // 未实现的方法
        result.notImplemented();
        break;
    }
  }

  /**
   * 播放抽奖音效
   * 根据抽奖类型播放不同的音效
   * @param call 方法调用对象，包含抽奖类型参数
   * @param result 结果回调
   */
  private void playRaffleSound(@NonNull MethodCall call, @NonNull Result result) {
    try {
      // 获取抽奖类型参数
      String type = call.argument("type");
      Log.d(TAG, "Playing raffle sound for type: " + type);
      
      // 这里可以根据不同的抽奖类型播放不同的音效
      // TODO: 实现不同抽奖类型的音效资源映射
      // 目前使用系统默认通知音效
      MediaPlayer mediaPlayer = MediaPlayer.create(context, android.provider.Settings.System.DEFAULT_NOTIFICATION_URI);
      if (mediaPlayer != null) {
        // 开始播放
        mediaPlayer.start();
        // 播放完成后释放资源
        mediaPlayer.setOnCompletionListener(MediaPlayer::release);
      }
      
      // 返回成功
      result.success(null);
    } catch (Exception e) {
      // 记录错误日志
      Log.e(TAG, "Error playing raffle sound", e);
      // 返回错误信息
      result.error("SOUND_ERROR", "Failed to play raffle sound", e.getMessage());
    }
  }

  /**
   * 触发设备震动
   * 根据指定的持续时间触发设备震动
   * @param call 方法调用对象，包含震动持续时间参数
   * @param result 结果回调
   */
  private void triggerVibration(@NonNull MethodCall call, @NonNull Result result) {
    try {
      // 获取震动持续时间参数，默认为100毫秒
      Integer duration = call.argument("duration");
      if (duration == null) duration = 100;
      
      // 检查设备是否支持震动
      if (vibrator != null && vibrator.hasVibrator()) {
        // 根据Android版本使用不同的震动API
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
          // Android 8.0及以上使用VibrationEffect
          vibrator.vibrate(VibrationEffect.createOneShot(duration, VibrationEffect.DEFAULT_AMPLITUDE));
        } else {
          // Android 8.0以下使用旧API
          //@SuppressWarnings("deprecation")
          vibrator.vibrate(duration);
        }
      }
      
      // 返回成功
      result.success(null);
    } catch (Exception e) {
      // 记录错误日志
      Log.e(TAG, "Error triggering vibration", e);
      // 返回错误信息
      result.error("VIBRATION_ERROR", "Failed to trigger vibration", e.getMessage());
    }
  }

  /**
   * 保存抽奖结果
   * 将抽奖结果保存到本地存储中
   * @param call 方法调用对象，包含抽奖结果数据
   * @param result 结果回调
   */
  private void saveRaffleResult(@NonNull MethodCall call, @NonNull Result result) {
    try {
      // 获取抽奖结果数据
      @SuppressWarnings("unchecked")
      Map<String, Object> raffleResult = (Map<String, Object>) call.arguments;
      
      // 获取现有历史记录
      List<Map<String, Object>> history = getRaffleHistoryFromPrefs();
      
      // 添加新记录
      history.add(raffleResult);
      
      // 限制历史记录数量（最多保存100条）
      // 如果超过100条，则只保留最新的100条
      if (history.size() > 100) {
        history = history.subList(history.size() - 100, history.size());
      }
      
      // 将历史记录转换为JSON字符串
      String historyJson = gson.toJson(history);
      // 保存到SharedPreferences
      prefs.edit().putString(HISTORY_KEY, historyJson).apply();
      
      // 返回成功
      result.success(null);
    } catch (Exception e) {
      // 记录错误日志
      Log.e(TAG, "Error saving raffle result", e);
      // 返回错误信息
      result.error("SAVE_ERROR", "Failed to save raffle result", e.getMessage());
    }
  }

  /**
   * 获取抽奖历史记录
   * 从本地存储中读取所有抽奖历史记录
   * @param result 结果回调
   */
  private void getRaffleHistory(@NonNull Result result) {
    try {
      // 从SharedPreferences中获取历史记录
      List<Map<String, Object>> history = getRaffleHistoryFromPrefs();
      // 返回历史记录列表
      result.success(history);
    } catch (Exception e) {
      // 记录错误日志
      Log.e(TAG, "Error getting raffle history", e);
      // 返回错误信息
      result.error("HISTORY_ERROR", "Failed to get raffle history", e.getMessage());
    }
  }

  /**
   * 从SharedPreferences中获取抽奖历史记录
   * 将JSON字符串转换为对象列表
   * @return 抽奖历史记录列表
   */
  private List<Map<String, Object>> getRaffleHistoryFromPrefs() {
    // 从SharedPreferences中获取JSON字符串，默认为空数组
    String historyJson = prefs.getString(HISTORY_KEY, "[]");
    // 创建泛型类型，用于JSON转换
    Type listType = new TypeToken<List<Map<String, Object>>>(){}.getType();
    // 将JSON字符串转换为对象列表并返回
    return gson.fromJson(historyJson, listType);
  }

  /**
   * 插件从Flutter引擎分离时调用
   * 清理资源和引用
   * @param binding Flutter插件绑定对象
   */
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    // 移除方法调用处理器，防止内存泄漏
    channel.setMethodCallHandler(null);
  }
}
