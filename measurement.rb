module PerformanceMonitor
  class Measurement
    def initialize(thread_buffer, storage)
      @thread_buffer = thread_buffer
      @storage = storage
    end

    def record
      @thread_buffer.clear
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        yield
      ensure
        finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        duration_ms = ((finish_time - start_time) * 1000).round(2)

        if action_payload = @thread_buffer.action_data
          action_attributes = {
            controller: action_payload[:controller],
            action:     action_payload[:action],
            method:     action_payload[:method],
            path:       action_payload[:path],
            status:     action_payload[:status],
            format:     action_payload[:format]
          }

          raw_sqls = @thread_buffer.sql_data || []
          
          sql_attributes = raw_sqls.map do |sql_event|
            {
              name:     sql_event[:payload][:name],
              sql:      sql_event[:payload][:sql],
              duration: ((sql_event[:finish] - sql_event[:start]) * 1000).round(2)
            }
          end

          sql_count = sql_attributes.size
          total_sql_duration_ms = sql_attributes.sum { |s| s[:duration] }.round(2)

          @storage.append(
            action_event:          action_attributes,
            sql_events:            sql_attributes,
            sql_count:             sql_count,
            total_sql_duration_ms: total_sql_duration_ms,
            total_time_ms:         duration_ms
          )
        end

        @thread_buffer.clear
      end
    end
  end
end