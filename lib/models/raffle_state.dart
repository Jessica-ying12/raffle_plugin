/// 抽奖状态枚举
/// 
/// 表示抽奖组件当前的运行状态
/// 用于控制抽奖流程和UI展示
enum RaffleState {
  /// 空闲状态
  idle,
  /// 运行中
  running,
  /// 已完成
  completed,
  /// 已停止
  stopped,
  /// 错误状态
  error,
}