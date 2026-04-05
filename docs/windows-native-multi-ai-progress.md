# Windows 原生多 AI 协作进展记录

更新时间：2026-04-05

## 目标

记录当前这条已经验证可用的 Windows 原生路线，避免后续又回到 WSL、脚本代理或半可用状态。

## 当前确认可用的路线

### 1. Windows 原生安装路线成立

- 当前以原生 Windows 环境为主，不依赖 WSL 才能跑通核心协作链路。
- 终端基础设施已经切换到 Windows 本地工具链。
- 这条路线的重点是先保证能稳定启动、稳定协作、稳定复用，而不是追求一次性把所有 AI 都塞进同一个复杂编排。

### 2. WezTerm 已安装

- WezTerm 已完成安装。
- 当前它是 Windows 本地多窗格协作的终端基础。
- 已验证它适合承载多 AI 分屏工作方式。

### 3. ccb 已在 Windows 原生环境安装

- `ccb` 已经在 Windows 原生环境完成安装。
- 当前进展不是“理论可装”，而是已经进入实际可用状态。
- 后续多 AI 协作继续以这套 Windows 原生安装结果为基础推进。

### 4. Codex 已修复可用

- Codex 已完成安装并可在当前环境使用。
- 之前的关键阻塞点是 `codex.ps1` 触发 PowerShell execution policy 限制。
- 当前采用的有效修复思路是：避免走 `codex.ps1` 这条会被 execution policy 卡住的入口。
- 结论：Codex 在 Windows 原生环境下已经恢复到可用状态。

### 5. Gemini 已安装、已认证、已修复可用

- Gemini 已完成安装。
- Gemini 已完成认证。
- 之前的关键阻塞点是 `gemini.ps1` 触发 PowerShell execution policy 限制。
- 当前采用的有效修复思路是：避免走 `gemini.ps1` 入口，改走不会被该策略直接拦住的可用入口。
- 结论：Gemini 在当前 Windows 原生环境下已经可正常参与协作。

### 6. OpenCode 已安装并完成初始化

- OpenCode 已完成安装。
- OpenCode 已完成初始化。
- 当前它的状态不是“未装”，而是“已具备后续接入条件”。

## 当前有效状态

- 一窗口多 AI 协作已经推进到 `Codex + Gemini` 同窗格体系可用。
- 当前有效形态是 `Codex + Gemini` split-pane 协作。
- OpenCode 已安装并初始化，但还没有挂入同一个第一协作窗口。
- 也就是说，当前最准确状态是：
  - `Codex` 可用
  - `Gemini` 可用
  - `OpenCode` 已就绪但尚未并入首个同窗协作面板

## 当前不可用项

### Claude

- Claude 在当前环境中暂时不可用。
- 当前原因不是本地安装步骤本身，而是区域 / 网络限制。
- 在这个限制解除前，不应把 Claude 计入“当前 Windows 原生多 AI 首版协作已完成”的范围。

## 实用结论

- 当前最稳妥的工作基线是：继续围绕 Windows 原生 `ccb + WezTerm + Codex + Gemini` 这条链路推进。
- OpenCode 可以作为下一步接入对象，但不应假装它已经并入当前首个同窗协作布局。
- Claude 目前应明确标记为环境受限，不应误记为配置问题或脚本问题。
