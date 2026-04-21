# quicktradepanel-mql5

[![Platform](https://img.shields.io/badge/Platform-MT5-1f6feb?style=flat-square)](https://www.metatrader5.com/) [![Language](https://img.shields.io/badge/Language-MQL5-00a86b?style=flat-square)](https://www.mql5.com/) [![Type](https://img.shields.io/badge/Type-Expert%20Advisor-ff8c00?style=flat-square)](https://github.com/kissMoona/quicktradepanel-mql5) [![License](https://img.shields.io/github/license/kissMoona/quicktradepanel-mql5?style=flat-square)](https://github.com/kissMoona/quicktradepanel-mql5/blob/main/LICENSE) [![Last Commit](https://img.shields.io/github/last-commit/kissMoona/quicktradepanel-mql5?style=flat-square)](https://github.com/kissMoona/quicktradepanel-mql5/commits/main) [![Stars](https://img.shields.io/github/stars/kissMoona/quicktradepanel-mql5?style=flat-square)](https://github.com/kissMoona/quicktradepanel-mql5/stargazers)

一个用于 MT5 的 MQL5 面板 EA，集成图表交互界面、批量止盈止损同步、浮盈加仓、组合保本损，以及箭头指标自动开单等功能。

中文说明：建议先在模拟环境中实验和开发交易策略。获取 Grand Markets 模拟账户注册：[点击这里](https://my.grandmarkets.com/auth/sso?utm_source=MTAwMzE0Mw==)

English: It is recommended to experiment with and develop trading strategies in a demo environment first. Register for a Grand Markets demo account here: [Click here](https://my.grandmarkets.com/auth/sso?utm_source=MTAwMzE0Mw==)

## 功能概览

- 图表交易面板：支持快速 `BUY`、`SELL`、`平多`、`平空`、`一键清仓`，并可直接调整手数。
- 批量 TP/SL 管理：面板输入一次止盈止损后，可同步到当前受管持仓。
- 拖动订单线回填：在图表上手动拖动订单的 `TP/SL` 后，可自动把数值回填到面板输入框。
- 顶部持仓信息面板：实时显示 `POS`、`AVG`、`LIQ`、`UPL`、`NET UPL` 等关键数据。
- 浮盈加仓：达到设定条件后自动按固定手数继续加仓。
- 组合保本/锁盈：加仓后可按整组仓位推送保护止损，避免利润大幅回吐。
- 箭头指标自动开单：可根据指标箭头方向自动开仓。
- 多周期确认过滤：主周期信号出现后，只有确认周期同方向时才允许开单。
- 单单模式：关闭浮盈加仓时，箭头自动交易按一次一单执行，新信号先处理旧仓再开新仓。
- 反向平仓：支持新方向开单时优先平掉反向持仓。

## 当前依赖

- 主程序：`Experts/QuickTradePanel.mq5`
- 编译文件：`Experts/QuickTradePanel.ex5`
- 指标依赖：`Indicators/halftrend-1.02.ex5`

## 安装方式

1. 将 `Experts/QuickTradePanel.ex5` 放入 MT5 的 `MQL5/Experts` 目录。
2. 将 `Indicators/halftrend-1.02.ex5` 放入 MT5 的 `MQL5/Indicators` 目录。
3. 重启 MT5，或者在导航器中刷新 `Experts` 与 `Indicators`。
4. 把 `QuickTradePanel` 加载到图表后，再根据需要配置手数、指标自动交易和多周期确认参数。

## CLI 快速下载

### 方式一：直接下载发行版压缩包（PowerShell）

```powershell
$tag = "v1.17"
Invoke-WebRequest -Uri "https://github.com/kissMoona/quicktradepanel-mql5/releases/download/$tag/quicktradepanel-mql5-v1.17.zip" -OutFile "quicktradepanel-mql5-v1.17.zip"
Invoke-WebRequest -Uri "https://github.com/kissMoona/quicktradepanel-mql5/releases/download/$tag/quicktradepanel-mql5-dependency-halftrend-v1.17.zip" -OutFile "quicktradepanel-mql5-dependency-halftrend-v1.17.zip"
```

### 方式二：直接克隆仓库

```powershell
git clone https://github.com/kissMoona/quicktradepanel-mql5.git
```

### 下载后放置位置

- `quicktradepanel-mql5-v1.17.zip` 中的 `Experts/QuickTradePanel.ex5` 放到 MT5 的 `MQL5/Experts`
- `quicktradepanel-mql5-dependency-halftrend-v1.17.zip` 中的 `Indicators/halftrend-1.02.ex5` 放到 MT5 的 `MQL5/Indicators`

## 支持项目与参与维护

如果你喜欢这个项目，欢迎按下面的顺序支持和参与维护：

1. 先在 GitHub 上给仓库点一个 `Star`
2. 再点击 `Watch`，及时接收版本更新和功能变更
3. 如果你想参与开发，可以先 `Fork` 这个仓库
4. 发现问题或有新想法时，欢迎提交 `Issue`
5. 完成改进后，可以通过 `Pull Request` 参与维护

仓库地址：

- [https://github.com/kissMoona/quicktradepanel-mql5](https://github.com/kissMoona/quicktradepanel-mql5)
