module PerformanceMonitor
  class RequestRecord
    NPlusOneQuery = Data.define(:sql, :count)

    IGNORED_SQL_NAMES = ["SCHEMA", "TRANSACTION"].freeze
    IGNORED_SQL_PREFIXES = /\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE|PRAGMA)\b/i.freeze

    def initialize(data, thresholds: {})
      @data = data
      @thresholds = thresholds || {}
      @action_event = data[:action_event] || {}
    end

    def controller_action
      "#{@action_event[:controller]}##{@action_event[:action]}"
    end

    def method_path
      "#{@action_event[:method]} #{@action_event[:path]}"
    end

    def status
      @action_event[:status]
    end

    def total_time_ms
      @data[:total_time_ms]
    end

    def sql_count
      @data[:sql_count]
    end

    def total_sql_duration_ms
      @data[:total_sql_duration_ms]
    end

    def slow?
      total_time_ms.to_f > (@thresholds[:time] || 300)
    end

    def high_query_count?
      sql_count.to_i > (@thresholds[:sql_count] || 20)
    end

    def n_plus_one?
      n_plus_one_queries.any?
    end

    # このリクエスト内で発生しているN+1クエリの種類数
    def n_plus_one_count
      n_plus_one_queries.count
    end

    # 検知されたすべてのN+1クエリ
    def n_plus_one_queries
      @n_plus_one_queries ||= begin
        events = @data[:sql_events] || []
        counts = Hash.new(0)

        events.each do |event|
          sql = event[:sql]
          next if sql.nil? || IGNORED_SQL_NAMES.include?(event[:name])
          next if sql.match?(IGNORED_SQL_PREFIXES)

          normalized = normalize_sql(sql)
          counts[normalized] += 1 unless normalized.empty?
        end

        threshold = @thresholds[:n_plus_one] || 5

        counts
          .select { |_, count| count >= threshold }
          .map { |sql, count| NPlusOneQuery.new(sql: sql, count: count) }
          .sort_by { |query| -query.count }
      end
    end

    private

    def normalize_sql(sql)
      s = sql.dup
      # コメント /* ... */ を除去
      s.gsub!(/\/\*.*?\*\//m, "")
      
      # 文字列リテラルを先に '?' へ置換
      s.gsub!(/'(?:''|\\'|[^'])*'/, "?")
      
      # 数値を '?' へ置換
      s.gsub!(/(?<![a-zA-Z0-9_])-?\b(?:0x[0-9a-fA-F]+|\d+(?:\.\d+)?)\b/, "?")
      
      # PostgreSQL等のプリペアドステートメント変数を '?' に統一
      s.gsub!(/\$\d+/, "?")

      # 連続するプレースホルダを単一の IN (?) に統合
      s.gsub!(/\bIN\s*\(\s*\?(?:\s*,\s*\?)*\s*\)/i, "IN (?)")
      
      # 連続する空白や改行を1つのスペースに統一
      s.gsub!(/\s+/, " ")
      s.strip!
      s
    end
  end
end