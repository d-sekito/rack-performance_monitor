require_relative "thread_buffer"
require_relative "storage"
require_relative "measurement"
require_relative "dashboard"
require_relative "request_record"

module PerformanceMonitor
  class Application
    DASHBOARD_PATH = "/__performance_monitor"

    def initialize(app, buffer_key: :performance_monitor_buffer, storage: Storage.new, thresholds: { time: 300, sql_count: 20 })
      @app = app
      @thread_buffer = ThreadBuffer.new(buffer_key)
      @storage = storage
      @dashboard_path = "/__performance_monitor"
      @thresholds = thresholds

      setup_subscriptions
    end

    def call(env)
      req = Rack::Request.new(env)
      return Dashboard.new(@storage, mount_path: @dashboard_path, thresholds: @thresholds).call(env) if req.path == @dashboard_path

      Measurement.new(@thread_buffer, @storage).record do
        @app.call(env)
      end
    end

    private

    def setup_subscriptions
      ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
        @thread_buffer.store_action(args.last)
      end

      ActiveSupport::Notifications.subscribe("sql.active_record") do |_, start, finish, _, payload|
        @thread_buffer.add_sql(payload, start, finish)
      end
    end
  end
end