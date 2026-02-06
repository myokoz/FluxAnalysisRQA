# FluxAnalysisRQA
森林炭素フラックスデータのリカレンス定量化解析（RQA）

## 概要

渦相関法で測定された森林-大気間の炭素フラックスデータに対して、
リカレンス定量化解析（RQA）を適用し、干ばつ年と平常年の動態を比較する。

## 必要環境

- Julia 1.9 以上
- 推奨: Pluto.jl（対話的ノートブック用）

## インストール
```bash
git clone https://github.com/あなたのユーザー名/FluxAnalysisRQA.git
cd FluxAnalysisRQA
julia --project=.
```

Juliaのパッケージモードで：
```julia
]instantiate
```

## 使い方

### 基本的な解析例
```julia
using FluxAnalysisRQA
include("examples/drought_analysis.jl")
```

### 対話的チュートリアル（Pluto.jl）
```julia
using Pluto
Pluto.run()
# ブラウザで notebooks/interactive_demo.jl を開く
```

## ディレクトリ構成
```
FluxAnalysisRQA/
├── src/              # 解析関数群
├── examples/         # 実行例
├── data/sample/      # サンプルデータ
├── docs/             # ドキュメント
├── notebooks/        # Plutoノートブック
└── README.md
```

## ライセンス

MIT License

## 引用

このコードを使用した場合は、以下を引用してください：
[****]

## 連絡先

[****]