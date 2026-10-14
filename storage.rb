require "json"
require "fileutils"

module PerformanceMonitor
  class Storage
    def initialize(file_path = Rails.root.join("tmp", "performance_monitor.jsonl"))
      @file_path = file_path
      FileUtils.mkdir_p(File.dirname(@file_path))
    end

    def append(attributes)
      File.open(@file_path, "a") do |f|
        f.puts(attributes.to_json)
      end
    end

    def read_all
      return [] unless File.exist?(@file_path)

      File.readlines(@file_path).map do |line|
        JSON.parse(line, symbolize_names: true)
      end
    end
  end
end