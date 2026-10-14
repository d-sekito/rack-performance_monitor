require "erb"
require_relative "request_record"
require_relative "request_records"

module PerformanceMonitor
  class Dashboard
    def initialize(storage, mount_path:, thresholds:)
      @storage = storage
      @mount_path = mount_path
      @thresholds = thresholds
      @template_path = File.expand_path("views/index.html.erb", __dir__)
    end

    def call(env)
      req = Rack::Request.new(env)
      
      raw_array = @storage.read_all.map do |data|
        RequestRecord.new(data, thresholds: @thresholds)
      end

      @records = RequestRecords.new(raw_array)
                   .filter_by(req.params["q"])
                   .sort_by_key(req.params["sort"], req.params["direction"])

      @params = req.params
      template_content = File.read(@template_path)
      body = ERB.new(template_content).result(binding)

      [
        200,
        {
          "content-type" => "text/html; charset=utf-8",
          "content-length" => body.bytesize.to_s
        },
        [body]
      ]
    end
  end
end