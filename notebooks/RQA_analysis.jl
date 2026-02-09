### A Pluto.jl notebook ###
# v0.20.21

using Markdown
using InteractiveUtils

# ╔═╡ fcfc8a78-05bf-11f1-b4f0-439ab4d60004
begin
    import Pkg
    # 1. ノートブックの場所(notebooks/)から一つ上の階層（ルート）を有効化
    # これによりProject.tomlに記載されたパッケージが使用可能になります
    Pkg.activate(joinpath(@__DIR__, ".."))
    
    # 2. 必要なライブラリの読み込み
    # using Plots
    # ※ CSVやDataFramesなど、サブプログラム内で必要なものはここでusingするか、
    # 各.jlファイルの中でusingされていればOKです。

    # 3. srcディレクトリにある3つのプログラムを順番に読み込む
    include(joinpath(@__DIR__, "..", "src", "data_loading.jl"))
    include(joinpath(@__DIR__, "..", "src", "drought_extract.jl"))
    include(joinpath(@__DIR__, "..", "src", "embedding.jl"))
    
    # 4. (任意) 読み込みが完了したことを示すメッセージ
    "プロジェクトの環境とソースコードを正常に読み込みました。"
end

# ╔═╡ 7ba4eb13-da38-4958-8ee7-24008e2f3f42
begin
    # プロジェクトルートからの相対パスで指定
    data_path = joinpath(@__DIR__, "..", "data", "data.xlsx")
    
    # data_loading.jl で定義されている関数を使ってデータをロード
    # 例：raw_data = load_my_data(data_path)
end

# ╔═╡ Cell order:
# ╠═fcfc8a78-05bf-11f1-b4f0-439ab4d60004
# ╠═7ba4eb13-da38-4958-8ee7-24008e2f3f42
