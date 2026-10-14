module PerformanceMonitor
  class ThreadBuffer
    def initialize(prefix)
      @action_key = :"#{prefix}_action"
      @sql_key    = :"#{prefix}_sql"
    end

    def store_action(payload)
      Thread.current[@action_key] = payload
    end

    def action_data
      Thread.current[@action_key]
    end

    def add_sql(payload, start, finish)
      Thread.current[@sql_key] ||= []
      Thread.current[@sql_key] << { payload: payload, start: start, finish: finish }
    end

    def sql_data
      Thread.current[@sql_key] || []
    end

    def clear
      Thread.current[@action_key] = nil
      Thread.current[@sql_key] = nil
    end
  end
end