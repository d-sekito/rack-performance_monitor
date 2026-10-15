require "rack"
require "erb"
require_relative "request"

module PerformanceMonitor
  class Dashboard
    ALLOWED_SORT_KEYS = %w[total_time_ms sql_count n_plus_one_count total_sql_duration_ms].freeze

    def initialize(storage, mount_path: nil, thresholds: {})
      @storage = storage
      @mount_path = mount_path
      @thresholds = thresholds
    end

    def call(env)
      req = Rack::Request.new(env)
      params = req.params
      query = params["q"]
      records = prepare_records(params)

      [
        200,
        { "Content-Type" => "text/html; charset=utf-8" },
        [render_html(mount_path: @mount_path, params: params, query: query, records: records)]
      ]
    end

    private

    def prepare_records(params)
      all_requests = @storage.read_all.map { |data| Request.new(data, thresholds: @thresholds) }
      filtered_requests = filter_requests(all_requests, params["q"])
      sort_requests(filtered_requests, params["sort"], params["direction"])
    end

    def filter_requests(requests, query)
      return requests if query.nil? || query.strip.empty?

      requests.select { |r| r.match?(query) }
    end

    def sort_requests(requests, sort_key, direction)
      return requests unless ALLOWED_SORT_KEYS.include?(sort_key)

      sorted = requests.sort_by(&sort_key.to_sym)
      direction == "asc" ? sorted : sorted.reverse
    end

    def render_html(**locals)
      template_path = File.expand_path("views/index.html.erb", __dir__)
      template = ERB.new(File.read(template_path))
      template.result_with_hash(locals)
    end
  end
end