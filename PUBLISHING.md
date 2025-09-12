# 发布Flutter插件到pub.dev指南

本文档提供了将Flutter插件发布到[pub.dev](https://pub.dev)的详细步骤，以便其他开发者可以使用您的插件。

## 发布前准备

### 1. 确保必要文件完整

- **pubspec.yaml**: 包含正确的元数据（名称、描述、版本、主页等）
- **LICENSE**: 开源许可证文件
- **CHANGELOG.md**: 版本更新日志
- **README.md**: 项目说明文档

### 2. 验证pubspec.yaml配置

确保以下字段已正确配置：

```yaml
name: raffle                                      # 包名，必须唯一
description: "一个功能丰富的Flutter抽奖插件..."    # 简短描述
version: 0.0.1                                   # 版本号
homepage: https://github.com/username/raffle     # 项目主页
repository: https://github.com/username/raffle   # 代码仓库
issue_tracker: https://github.com/username/raffle/issues  # 问题追踪
```

### 3. 验证代码质量

运行以下命令检查代码质量：

```bash
flutter analyze
flutter test
```

### 4. 验证示例项目

确保`example`目录下的示例项目能正常运行：

```bash
cd example
flutter run
```

## 发布流程

### 1. 登录pub.dev

首次发布需要登录到pub.dev：

```bash
flutter pub login
```

系统会打开浏览器，引导您完成Google账号授权流程。

### 2. 发布前检查

运行以下命令检查发布是否存在问题：

```bash
flutter pub publish --dry-run
```

这会模拟发布过程，但不会实际上传包。

### 3. 正式发布

如果一切正常，执行以下命令发布插件：

```bash
flutter pub publish
```

### 4. 验证发布结果

发布成功后，您可以在[pub.dev](https://pub.dev)上搜索您的包名来验证发布是否成功。

## 版本更新

当您需要发布新版本时：

1. 更新`pubspec.yaml`中的`version`字段
2. 在`CHANGELOG.md`中添加新版本的更新内容
3. 运行`flutter pub publish`发布新版本

## 注意事项

- 包名必须是唯一的，发布前可在pub.dev上搜索确认
- 描述应简洁明了，说明插件的主要功能
- 确保示例代码能正常运行，这对用户理解如何使用您的插件非常重要
- 良好的文档对提高插件质量和用户体验至关重要

## 常见问题

### Q: 如何撤回已发布的版本？

A: 已发布的版本无法撤回，但您可以发布新版本来修复问题。在极特殊情况下，可以联系pub.dev管理员请求帮助。

### Q: 如何将插件标记为废弃？

A: 在`pubspec.yaml`中添加`deprecated`字段：

```yaml
deprecated: 此插件已不再维护，请使用xxx替代
```

### Q: 如何转移插件所有权？

A: 目前pub.dev不支持直接转移所有权。建议在新账号下发布新包，并将原包标记为废弃。

---

祝您发布顺利！如有任何问题，请参考[pub.dev官方文档](https://dart.dev/tools/pub/publishing)。