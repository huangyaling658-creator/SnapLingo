# SnapLingo · 拍照学外语

> 拍张照片，AI 帮你认出画面里的东西，并教你它在目标语言里怎么说。

一款 iOS 应用：用相机拍下身边的物体，AI 识别画面内容，给出对应外语单词、读音和释义，边看边学、随手积累生词本。把"背单词"变成"看到什么学什么"。

## 功能

- 📸 **拍照识词**：对着物体拍照，AI 识别并给出外语单词
- 🔊 **发音朗读**：单词语音播报，跟读纠音
- 🌍 **多语言**：可选学习的目标语言
- 📒 **生词本**：自动收藏学过的词，分类管理
- 🕘 **历史记录**：回看每次拍照学到的内容
- 👤 **个人中心**：学习设置与进度

## 技术栈

- **平台**：iOS，Swift + SwiftUI
- **AI 识别**：Google Gemini（`GeminiService`）
- **语音**：系统语音合成（`SpeechService`）
- **本地存储**：`StorageService`（生词本 / 历史）
- 架构：MVVM（Views / ViewModels / Models / Services）

## 构建运行

```bash
open SnapLingo.xcodeproj
```

在 Xcode 中配置 Gemini API Key，选择目标设备 / 模拟器运行。

## 目录结构

```
SnapLingo/
├── Models/         ← Word / Language
├── Services/       ← GeminiService / SpeechService / StorageService
├── ViewModels/     ← SnapLingoViewModel
└── Views/          ← Home / History / Profile / ImagePicker + Components
```

---

由 [Santa](https://github.com/huangyaling658-creator) 一个人 + AI 打造。
