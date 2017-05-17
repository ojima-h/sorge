require 'securerandom'

module Sorge
  module Util
    module_function

    def symbolize_keys(obj)
      case obj
      when Hash
        obj.map { |k, v| [k.to_sym, symbolize_keys(v)] }.to_h
      when Array
        obj.map { |v| symbolize_keys(v) }
      else
        obj
      end
    end

    def format_error_info(error, depth = nil)
      error_info = ''
      error_info << "#{error.class}: #{error.message}\n"

      bt = error.backtrace || []
      bt = bt.first(depth) if depth
      bt.each do |line|
        error_info << ' ' * 8 + 'from ' + line + "\n"
      end
      error_info
    end

    def generate_id(n = 8)
      SecureRandom.hex(n / 2)
    end

    def Proc(value)
      return value if value.is_a? Proc
      proc { value }
    end

    def Time(time)
      case time
      when /\A\d+(.\d+)\z/ then Time.at(time.to_f)
      when Numeric then Time.at(time)
      when Date then time.to_time
      when Time then time
      when String then Time.parse(time)
      when ->(t) { t.respond_to?(:to_time) } then time.to_time
      else Time.parse(time)
      end
    end
  end
end
