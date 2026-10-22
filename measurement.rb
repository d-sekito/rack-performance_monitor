module PerformanceMonitor
  class Measurement
    def initialize(thread_buffer, storage)
      @thread_buffer = thread_buffer
      @storage = storage
    end

    def record
      @thread_buffer.start
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      begin
        yield
      ensure
        finish_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        total_time_ms = ((finish_time - start_time) * 1000.0).round(2)

        if (data = @thread_buffer.finish(total_time_ms))
          @storage.append(data)
        end
      end
    end
  end
end