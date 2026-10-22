module PerformanceMonitor
  class ThreadBuffer
    def initialize(key)
      @key = key
    end

    def start
      Thread.current[@key] = {
        action_event: {},
        sql_events: [],
        sql_count: 0,
        total_sql_duration_ms: 0.0
      }
    end

    def finish(total_time_ms)
      data = Thread.current[@key]
      Thread.current[@key] = nil
      return nil if data.nil? || data[:action_event].empty?

      data[:total_time_ms] = total_time_ms
      data[:total_sql_duration_ms] = data[:total_sql_duration_ms].round(2)
      data
    end

    def store_action(payload)
      current = Thread.current[@key]
      return unless current

      current[:action_event] = {
        controller: payload[:controller],
        action: payload[:action],
        method: payload[:method],
        path: payload[:path],
        status: payload[:status]
      }
    end

    def add_sql(payload, start_time, finish_time)
      current = Thread.current[@key]
      return unless current

      duration = ((finish_time - start_time) * 1000.0).round(2)
      current[:sql_events] << {
        name: payload[:name],
        sql: payload[:sql],
        duration_ms: duration
      }
      current[:sql_count] += 1
      current[:total_sql_duration_ms] += duration
    end
  end
end