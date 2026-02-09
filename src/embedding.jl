"""
embedding.jl

状態空間の再構成（embedding）とリカレンスプロット作成
1. 状態空間への埋め込み
2. リカレンス行列の計算
3. リカレンスプロットの作成
"""

using LinearAlgebra
using Statistics
using Plots

# 3Dプロット用のバックエンドを有効化
plotly()  # または gr()

# ========================================
# 状態空間の再構成
# ========================================

"""
    create_embedding(data::Vector{Float64}, m::Int, tau::Int) -> Matrix{Float64}

時系列データを状態空間に埋め込む

# 引数
- data: 時系列データ（1次元配列）
- m: 埋め込み次元
- tau: 時間遅れ

# 戻り値
- embedded_data: 埋め込まれたデータ（n × m 行列）

# 例
```julia
data = [1.0, 2.0, 3.0, 4.0, 5.0]
embedded = create_embedding(data, 3, 1)
# 結果: [1.0 2.0 3.0]
#       [2.0 3.0 4.0]
#       [3.0 4.0 5.0]
```
"""
function create_embedding(data::Vector{Float64}, m::Int, tau::Int)
    n = length(data)
    n_embedded = n - (m - 1) * tau
    
    if n_embedded <= 0
        error("データが短すぎます。データ長=$(n), 必要長=$((m-1)*tau + 1)")
    end
    
    embedded_data = zeros(Float64, n_embedded, m)
    
    for i in 1:n_embedded
        for j in 1:m
            idx = i + (j - 1) * tau
            embedded_data[i, j] = data[idx]
        end
    end
    
    return embedded_data
end

# ========================================
# リカレンス行列の計算
# ========================================

"""
    plot_state_space_3d(
        embedded_data::Matrix{Float64};
        title::String="State Space (3D)",
        color_by_time::Bool=true
    ) -> Plot

埋め込まれたデータを3D状態空間にプロットする

# 引数
- embedded_data: 埋め込まれたデータ（n × m 行列、m >= 3）
- title: プロットのタイトル
- color_by_time: 時間経過で色分けするか（デフォルト: true）

# 戻り値
- plot: 3Dプロット

# 注意
埋め込み次元が3以上である必要があります
"""
function plot_state_space_3d(
    embedded_data::Matrix{Float64};
    title::String="State Space (3D)",
    color_by_time::Bool=true
)
    m = size(embedded_data, 2)
    
    if m < 3
        error("3Dプロットには埋め込み次元が3以上必要です（現在: m=$m）")
    end
    
    # 最初の3次元を使用
    x = embedded_data[:, 1]
    y = embedded_data[:, 2]
    z = embedded_data[:, 3]
    
    if color_by_time
        # 時間経過で色分け
        n = length(x)
        time_indices = 1:n
        
        p = plot3d(
            x, y, z,
            line_z=time_indices,
            color=:viridis,
            linewidth=1.5,
            title=title,
            xlabel="x(t)",
            ylabel="x(t+τ)",
            zlabel="x(t+2τ)",
            label="",
            colorbar_title="Time",
            size=(800, 600),
            camera=(45, 30)  # 視点角度
        )
    else
        # 単色
        p = plot3d(
            x, y, z,
            color=:blue,
            linewidth=1.5,
            title=title,
            xlabel="x(t)",
            ylabel="x(t+τ)",
            zlabel="x(t+2τ)",
            label="",
            size=(800, 600),
            camera=(45, 30)
        )
    end
    
    return p
end

"""
    plot_state_space_with_projection(
        embedded_data::Matrix{Float64};
        title::String="State Space with Projections"
    ) -> Plot

3D状態空間プロットと各平面への射影を表示

# 引数
- embedded_data: 埋め込まれたデータ（n × m 行列、m >= 3）
- title: プロットのタイトル

# 戻り値
- plot: 複合プロット（3D + 3つの2D射影）
"""
function plot_state_space_with_projection(
    embedded_data::Matrix{Float64};
    title::String="State Space with Projections"
)
    m = size(embedded_data, 2)
    
    if m < 3
        error("3Dプロットには埋め込み次元が3以上必要です（現在: m=$m）")
    end
    
    x = embedded_data[:, 1]
    y = embedded_data[:, 2]
    z = embedded_data[:, 3]
    
    # 3Dプロット
    p1 = plot3d(
        x, y, z,
        color=:blue,
        linewidth=1.5,
        title="3D State Space",
        xlabel="x(t)",
        ylabel="x(t+τ)",
        zlabel="x(t+2τ)",
        label="",
        size=(400, 400),
        camera=(45, 30)
    )
    
    # XY平面への射影
    p2 = plot(
        x, y,
        color=:red,
        linewidth=1,
        title="XY Projection",
        xlabel="x(t)",
        ylabel="x(t+τ)",
        label="",
        size=(300, 300),
        aspect_ratio=:equal
    )
    
    # XZ平面への射影
    p3 = plot(
        x, z,
        color=:green,
        linewidth=1,
        title="XZ Projection",
        xlabel="x(t)",
        ylabel="x(t+2τ)",
        label="",
        size=(300, 300),
        aspect_ratio=:equal
    )
    
    # YZ平面への射影
    p4 = plot(
        y, z,
        color=:purple,
        linewidth=1,
        title="YZ Projection",
        xlabel="x(t+τ)",
        ylabel="x(t+2τ)",
        label="",
        size=(300, 300),
        aspect_ratio=:equal
    )
    
    # 全体を組み合わせ
    p_combined = plot(
        p1, p2, p3, p4,
        layout=(2, 2),
        size=(1000, 800),
        plot_title=title
    )
    
    return p_combined
end

# ========================================
# リカレンス統計量の計算
# ========================================

"""
    calculate_rqa_statistics(rec_matrix::Matrix{Int}) -> Dict

リカレンス行列からRQA統計量を計算

# 引数
- rec_matrix: リカレンス行列（n × n の0/1行列）

# 戻り値
辞書形式のRQA統計量:
- RR: Recurrence Rate (再帰率)
- DET: Determinism (決定論性)
- LAM: Laminarity (ラミナリティ)
- L: Average diagonal line length (対角線の平均長)
- L_max: Maximum diagonal line length (対角線の最大長)
- ENTR: Entropy of diagonal line lengths (対角線長のエントロピー)
- V_max: Maximum vertical line length (垂直線の最大長)
- TT: Trapping time (平均垂直線長)
- V_ENTR: Entropy of vertical line lengths (垂直線長のエントロピー)

# 参考文献
Marwan, N., et al. (2007). Recurrence plots for the analysis of complex systems.
Physics Reports, 438(5-6), 237-329.
"""
function calculate_rqa_statistics(rec_matrix::Matrix{Int})
    n = size(rec_matrix, 1)
    
    # ========================================
    # 1. Recurrence Rate (RR) - 再帰率
    # ========================================
    # リカレンス行列内の1の割合
    RR = sum(rec_matrix) / (n * n)
    
    # ========================================
    # 2. 対角線の解析（Determinism関連）
    # ========================================
    # 対角線長の分布を計算
    diag_lengths = Int[]
    
    # 主対角線を除く各対角線について
    for k in 1:(n-1)
        # 上三角部分の対角線
        diag_upper = [rec_matrix[i, i+k] for i in 1:(n-k)]
        lengths_upper = get_line_lengths(diag_upper)
        append!(diag_lengths, lengths_upper)
        
        # 下三角部分の対角線
        diag_lower = [rec_matrix[i+k, i] for i in 1:(n-k)]
        lengths_lower = get_line_lengths(diag_lower)
        append!(diag_lengths, lengths_lower)
    end
    
    # 最小長を2以上とする（1点だけの再帰は除外）
    l_min = 2
    diag_lengths_filtered = filter(l -> l >= l_min, diag_lengths)
    
    if isempty(diag_lengths_filtered)
        DET = 0.0
        L = 0.0
        L_max = 0
        ENTR = 0.0
    else
        # DET: 決定論性（長さl_min以上の対角線に含まれる点の割合）
        total_diagonal_points = sum(diag_lengths_filtered)
        total_recurrence_points = sum(diag_lengths)  # すべての対角線上の点
        DET = total_diagonal_points / max(total_recurrence_points, 1)
        
        # L: 対角線の平均長
        L = mean(diag_lengths_filtered)
        
        # L_max: 対角線の最大長
        L_max = maximum(diag_lengths_filtered)
        
        # ENTR: 対角線長の分布のエントロピー
        ENTR = calculate_entropy(diag_lengths_filtered)
    end
    
    # ========================================
    # 3. 垂直線の解析（Laminarity関連）
    # ========================================
    # 各列の垂直線長を計算
    vert_lengths = Int[]
    
    for j in 1:n
        column = rec_matrix[:, j]
        lengths = get_line_lengths(column)
        append!(vert_lengths, lengths)
    end
    
    # 最小長を2以上とする
    v_min = 2
    vert_lengths_filtered = filter(v -> v >= v_min, vert_lengths)
    
    if isempty(vert_lengths_filtered)
        LAM = 0.0
        TT = 0.0
        V_max = 0
        V_ENTR = 0.0
    else
        # LAM: ラミナリティ（長さv_min以上の垂直線に含まれる点の割合）
        total_vertical_points = sum(vert_lengths_filtered)
        total_recurrence_points_vert = sum(vert_lengths)
        LAM = total_vertical_points / max(total_recurrence_points_vert, 1)
        
        # TT: Trapping time（垂直線の平均長）
        TT = mean(vert_lengths_filtered)
        
        # V_max: 垂直線の最大長
        V_max = maximum(vert_lengths_filtered)
        
        # V_ENTR: 垂直線長の分布のエントロピー
        V_ENTR = calculate_entropy(vert_lengths_filtered)
    end
    
    # 結果を辞書で返す
    return Dict(
        "RR" => RR,
        "DET" => DET,
        "LAM" => LAM,
        "L" => L,
        "L_max" => L_max,
        "ENTR" => ENTR,
        "TT" => TT,
        "V_max" => V_max,
        "V_ENTR" => V_ENTR
    )
end

"""
    get_line_lengths(binary_vector::Vector{Int}) -> Vector{Int}

2値ベクトルから連続した1の長さを抽出

# 引数
- binary_vector: 0と1からなるベクトル

# 戻り値
- 連続した1の長さのベクトル

# 例
```julia
get_line_lengths([0, 1, 1, 1, 0, 1, 1, 0])  # [3, 2]
```
"""
function get_line_lengths(binary_vector::Vector{Int})
    lengths = Int[]
    current_length = 0
    
    for value in binary_vector
        if value == 1
            current_length += 1
        else
            if current_length > 0
                push!(lengths, current_length)
                current_length = 0
            end
        end
    end
    
    # 最後に1で終わる場合
    if current_length > 0
        push!(lengths, current_length)
    end
    
    return lengths
end

"""
    calculate_entropy(lengths::Vector{Int}) -> Float64

線長分布のシャノンエントロピーを計算

# 引数
- lengths: 線長のベクトル

# 戻り値
- エントロピー値
"""
function calculate_entropy(lengths::Vector{Int})
    if isempty(lengths)
        return 0.0
    end
    
    # 各長さの出現頻度を計算
    length_counts = Dict{Int, Int}()
    for l in lengths
        length_counts[l] = get(length_counts, l, 0) + 1
    end
    
    # 確率分布に変換
    total = length(lengths)
    probabilities = [count / total for count in values(length_counts)]
    
    # エントロピーを計算
    entropy = -sum(p * log(p) for p in probabilities if p > 0)
    
    return entropy
end

"""
    print_rqa_statistics(rqa_stats::Dict; title::String="RQA Statistics")

RQA統計量を整形して表示

# 引数
- rqa_stats: calculate_rqa_statistics()の戻り値
- title: 表示タイトル
"""
function print_rqa_statistics(rqa_stats::Dict; title::String="RQA Statistics")
    println("\n" * "=" ^ 60)
    println(title)
    println("=" ^ 60)
    
    # 主要な指標（必須）
    println("\n【主要指標】")
    @printf("  RR  (Recurrence Rate)    : %.4f (%.2f%%)\n", 
            rqa_stats["RR"], rqa_stats["RR"] * 100)
    @printf("  DET (Determinism)        : %.4f (%.2f%%)\n", 
            rqa_stats["DET"], rqa_stats["DET"] * 100)
    @printf("  LAM (Laminarity)         : %.4f (%.2f%%)\n", 
            rqa_stats["LAM"], rqa_stats["LAM"] * 100)
    
    # 対角線関連の指標
    println("\n【対角線指標】")
    @printf("  L     (Average diagonal line)  : %.2f\n", rqa_stats["L"])
    @printf("  L_max (Maximum diagonal line)  : %d\n", rqa_stats["L_max"])
    @printf("  ENTR  (Diagonal line entropy)  : %.4f\n", rqa_stats["ENTR"])
    
    # 垂直線関連の指標
    println("\n【垂直線指標】")
    @printf("  TT    (Trapping time)          : %.2f\n", rqa_stats["TT"])
    @printf("  V_max (Maximum vertical line)  : %d\n", rqa_stats["V_max"])
    @printf("  V_ENTR(Vertical line entropy)  : %.4f\n", rqa_stats["V_ENTR"])
    
    println("=" ^ 60)
end

# ========================================
# 4. リカレンス行列の計算（元の位置）
# ========================================

"""
    create_recurrence_matrix(embedded_data::Matrix{Float64}, threshold::Float64) -> Matrix{Int}

リカレンス行列を作成する

# 引数
- embedded_data: 埋め込まれたデータ（n × m 行列）
- threshold: 閾値（この値以下の距離を再帰とみなす）

# 戻り値
- rec_matrix: リカレンス行列（n × n の0/1行列）

# 説明
各点間のユークリッド距離を計算し、閾値以下なら1、それ以外は0
"""
function create_recurrence_matrix(embedded_data::Matrix{Float64}, threshold::Float64)
    n = size(embedded_data, 1)
    rec_matrix = zeros(Int, n, n)
    
    # 各点間のユークリッド距離を計算
    for i in 1:n
        for j in 1:n
            distance = norm(embedded_data[i, :] - embedded_data[j, :])
            
            # 閾値以下なら1、それ以外は0
            if distance <= threshold
                rec_matrix[i, j] = 1
            end
        end
    end
    
    return rec_matrix
end

# ========================================
# 5. リカレンスプロットを作成する関数
# ========================================

"""
    plot_recurrence(
        flux_data::Dict,
        year::Int,
        start_month::Int,
        end_month::Int,
        season_name::String;
        m::Int=3,
        tau::Int=1,
        threshold_quantile::Float64=0.10,
        plot_state_space::Bool=true,
        print_statistics::Bool=true
    ) -> Tuple

指定された期間のリカレンスプロットを作成

# 引数
- flux_data: data_loading.jl で作成したデータ
- year: 年
- start_month: 開始月
- end_month: 終了月
- season_name: 季節名（表示用）
- m: 埋め込み次元（デフォルト: 3）
- tau: 時間遅れ（デフォルト: 1）
- threshold_quantile: 閾値を決定するための分位点（デフォルト: 0.10）
- plot_state_space: 3D状態空間プロットも作成するか（デフォルト: true）
- print_statistics: RQA統計量を表示するか（デフォルト: true）

# 戻り値
- embedded_data: 埋め込まれたデータ
- rec_matrix: リカレンス行列
- rqa_stats: RQA統計量（辞書）
- rec_plot: リカレンスプロット
- state_plot: 3D状態空間プロット（plot_state_space=true の場合）
"""
function plot_recurrence(
    flux_data::Dict,
    year::Int,
    start_month::Int,
    end_month::Int,
    season_name::String;
    m::Int=3,
    tau::Int=1,
    threshold_quantile::Float64=0.10,
    plot_state_space::Bool=true,
    print_statistics::Bool=true
)
    println("\n========================================")
    println("Year: $year, Season: $season_name")
    
    # 日平均NEEデータを取得
    daily_nee = create_daily_mean_nee(flux_data, year, start_month, end_month)
    nee_values = daily_nee["values"]
    
    # デバッグ: nee_valuesの型を確認
    if !(nee_values isa Vector)
        error("nee_valuesがベクトルではありません。型: $(typeof(nee_values))")
    end
    
    println("データ点数: $(length(nee_values))")
    
    # 状態空間埋め込み
    embedded_data = create_embedding(nee_values, m, tau)
    
    println("埋め込み後のデータ点数: $(size(embedded_data, 1))")
    
    # 閾値を設定（距離の分位点）
    n_embedded = size(embedded_data, 1)
    all_distances = Float64[]
    
    for i in 1:n_embedded
        for j in (i+1):n_embedded
            distance = norm(embedded_data[i, :] - embedded_data[j, :])
            push!(all_distances, distance)
        end
    end
    
    # デバッグ: all_distancesの型と内容を確認
    if isempty(all_distances)
        error("all_distancesが空です")
    end
    if !(all_distances isa Vector{Float64})
        error("all_distancesが正しい型ではありません。型: $(typeof(all_distances))")
    end
    
    # 指定された分位点で閾値を設定
    threshold = quantile(all_distances, threshold_quantile)
    
    println("閾値: $(round(threshold, digits=4))")
    println("========================================\n")
    
    # リカレンス行列を作成
    rec_matrix = create_recurrence_matrix(embedded_data, threshold)
    
    # RQA統計量を計算
    rqa_stats = calculate_rqa_statistics(rec_matrix)
    
    # 統計量を表示
    if print_statistics
        print_rqa_statistics(rqa_stats, title="RQA Statistics - $year $season_name")
    end
    
    # リカレンスプロットを表示
    rec_plot = heatmap(
        rec_matrix,
        color=:grays,
        colorbar=false,
        title="Recurrence Plot - $year $season_name",
        xlabel="Time Index",
        ylabel="Time Index",
        size=(600, 600),
        aspect_ratio=:equal,
        yflip=true,  # y軸を反転（Wolframと同じ向き）
        framestyle=:box
    )
    
    # 3D状態空間プロットを作成（m >= 3 の場合）
    if plot_state_space && m >= 3
        state_plot = plot_state_space_3d(
            embedded_data;
            title="State Space - $year $season_name",
            color_by_time=true
        )
        
        return embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot
    else
        return embedded_data, rec_matrix, rqa_stats, rec_plot, nothing
    end
end

# ========================================
# 複数年のリカレンスプロットを一括作成
# ========================================

"""
    plot_recurrence_for_years(
        flux_data::Dict,
        years::Vector{Int},
        start_month::Int,
        end_month::Int,
        season_name::String;
        m::Int=3,
        tau::Int=1,
        threshold_quantile::Float64=0.10,
        plot_state_space::Bool=true,
        print_statistics::Bool=true
    ) -> Dict

複数年のリカレンスプロットを一括作成

# 戻り値
辞書形式: Dict(year => (embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot))
"""
function plot_recurrence_for_years(
    flux_data::Dict,
    years::Vector{Int},
    start_month::Int,
    end_month::Int,
    season_name::String;
    m::Int=3,
    tau::Int=1,
    threshold_quantile::Float64=0.10,
    plot_state_space::Bool=true,
    print_statistics::Bool=true
)
    results = Dict{Int, Tuple}()
    
    for year in years
        embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot = plot_recurrence(
            flux_data,
            year,
            start_month,
            end_month,
            season_name;
            m=m,
            tau=tau,
            threshold_quantile=threshold_quantile,
            plot_state_space=plot_state_space,
            print_statistics=print_statistics
        )
        
        results[year] = (embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot)
        
        # プロットを表示
        display(rec_plot)
        if !isnothing(state_plot)
            display(state_plot)
        end
    end
    
    return results
end

# ========================================
# 干ばつ年と通常年のリカレンスプロット比較
# ========================================

"""
    compare_recurrence_drought_vs_normal(
        flux_data::Dict,
        drought_classification::Dict;
        start_month::Int=3,
        end_month::Int=5,
        m::Int=3,
        tau::Int=1,
        threshold_quantile::Float64=0.10,
        plot_state_space::Bool=true,
        print_statistics::Bool=true
    )

干ばつ年と通常年のリカレンスプロットを比較

# 引数
- flux_data: data_loading.jl で作成したデータ
- drought_classification: drought_extract.jl で作成した分類結果
- start_month: 開始月（デフォルト: 3月）
- end_month: 終了月（デフォルト: 5月）
- m: 埋め込み次元
- tau: 時間遅れ
- threshold_quantile: 閾値の分位点
- plot_state_space: 3D状態空間プロットも作成するか
- print_statistics: RQA統計量を表示するか
"""
function compare_recurrence_drought_vs_normal(
    flux_data::Dict,
    drought_classification::Dict;
    start_month::Int=3,
    end_month::Int=5,
    m::Int=3,
    tau::Int=1,
    threshold_quantile::Float64=0.10,
    plot_state_space::Bool=true,
    print_statistics::Bool=true
)
    drought_years = drought_classification["drought_years"]
    normal_years = drought_classification["normal_years"]
    
    println("\n" * "=" ^ 70)
    println("干ばつ年のリカレンスプロットと状態空間")
    println("=" ^ 70)
    
    drought_results = Dict{Int, Tuple}()
    for year in drought_years
        embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot = plot_recurrence(
            flux_data,
            year,
            start_month,
            end_month,
            "Spring (Drought)";
            m=m,
            tau=tau,
            threshold_quantile=threshold_quantile,
            plot_state_space=plot_state_space,
            print_statistics=print_statistics
        )
        
        drought_results[year] = (embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot)
        display(rec_plot)
        if !isnothing(state_plot)
            display(state_plot)
        end
    end
    
    println("\n" * "=" ^ 70)
    println("通常年のリカレンスプロットと状態空間")
    println("=" ^ 70)
    
    normal_results = Dict{Int, Tuple}()
    for year in normal_years
        embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot = plot_recurrence(
            flux_data,
            year,
            start_month,
            end_month,
            "Spring (Normal)";
            m=m,
            tau=tau,
            threshold_quantile=threshold_quantile,
            plot_state_space=plot_state_space,
            print_statistics=print_statistics
        )
        
        normal_results[year] = (embedded_data, rec_matrix, rqa_stats, rec_plot, state_plot)
        display(rec_plot)
        if !isnothing(state_plot)
            display(state_plot)
        end
    end
    
    # 統計的比較サマリーを表示
    if print_statistics
        print_comparison_summary(drought_results, normal_results)
    end
    
    return Dict(
        "drought" => drought_results,
        "normal" => normal_results
    )
end

"""
    print_comparison_summary(drought_results::Dict, normal_results::Dict)

干ばつ年と通常年のRQA統計量の比較サマリーを表示
"""
function print_comparison_summary(drought_results::Dict, normal_results::Dict)
    println("\n" * "=" ^ 70)
    println("干ばつ年 vs 通常年 - RQA統計量の比較")
    println("=" ^ 70)
    
    # 干ばつ年の統計量を集計
    drought_stats_list = [result[3] for result in values(drought_results)]  # result[3] = rqa_stats
    normal_stats_list = [result[3] for result in values(normal_results)]
    
    # 各指標の平均を計算
    metrics = ["RR", "DET", "LAM", "L", "L_max", "ENTR", "TT", "V_max", "V_ENTR"]
    
    println("\n指標          | 干ばつ年(平均) | 通常年(平均)   | 差分")
    println("-" ^ 70)
    
    for metric in metrics
        drought_values = [stats[metric] for stats in drought_stats_list]
        normal_values = [stats[metric] for stats in normal_stats_list]
        
        drought_mean = mean(drought_values)
        normal_mean = mean(normal_values)
        diff = drought_mean - normal_mean
        
        if metric in ["L_max", "V_max"]
            @printf("%-13s | %14.1f | %14.1f | %+.1f\n", 
                    metric, drought_mean, normal_mean, diff)
        elseif metric in ["L", "TT"]
            @printf("%-13s | %14.2f | %14.2f | %+.2f\n", 
                    metric, drought_mean, normal_mean, diff)
        else
            @printf("%-13s | %14.4f | %14.4f | %+.4f\n", 
                    metric, drought_mean, normal_mean, diff)
        end
    end
    
    println("=" ^ 70)
    
    # 個別年の詳細（年でソート）
    println("\n【干ばつ年の詳細】")
    drought_years_sorted = sort(collect(keys(drought_results)))  # 年のみをソート
    for year in drought_years_sorted
        rqa_stats = drought_results[year][3]  # タプルの3番目がrqa_stats
        @printf("  %d: RR=%.3f, DET=%.3f, LAM=%.3f\n", 
                year, rqa_stats["RR"], rqa_stats["DET"], rqa_stats["LAM"])
    end
    
    println("\n【通常年の詳細】")
    normal_years_sorted = sort(collect(keys(normal_results)))  # 年のみをソート
    for year in normal_years_sorted
        rqa_stats = normal_results[year][3]  # タプルの3番目がrqa_stats
        @printf("  %d: RR=%.3f, DET=%.3f, LAM=%.3f\n", 
                year, rqa_stats["RR"], rqa_stats["DET"], rqa_stats["LAM"])
    end
    
    println()
end

println("\nembedding.jl が読み込まれました")
println("利用可能な関数:")
println("  - create_embedding(data, m, tau)")
println("  - create_recurrence_matrix(embedded_data, threshold)")
println("  - calculate_rqa_statistics(rec_matrix)")
println("  - print_rqa_statistics(rqa_stats)")
println("  - plot_state_space_3d(embedded_data)")
println("  - plot_state_space_with_projection(embedded_data)")
println("  - plot_recurrence(flux_data, year, start_month, end_month, season_name)")
println("  - compare_recurrence_drought_vs_normal(flux_data, drought_classification)")
println()