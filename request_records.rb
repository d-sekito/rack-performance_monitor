require "forwardable"

module PerformanceMonitor
  class RequestRecords
    extend Forwardable
    def_delegators :@records, :each, :size, :reverse_each

    def initialize(records)
      @records = records
    end

    def filter_by(query)
      return self if query.nil? || query.strip.empty?

      q = query.downcase
      filtered = @records.select do |r|
        r.controller_action.downcase.include?(q) || r.method_path.downcase.include?(q)
      end

      self.class.new(filtered)
    end

    def sort_by_key(sort_key, direction)
      return self.class.new(@records.reverse) if sort_key.nil? || sort_key.empty?

      sorted = case sort_key
               when "time"       then @records.sort_by(&:total_time_ms)
               when "sql_count"  then @records.sort_by(&:sql_count)
               when "n_plus_one" then @records.sort_by(&:n_plus_one_count)
               when "sql_time"   then @records.sort_by(&:total_sql_duration_ms)
               else @records
               end

      sorted = direction == "asc" ? sorted : sorted.reverse
      self.class.new(sorted)
    end
  end
end