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

    def format_error_info(error)
      error_info = ''
      error_info << "#{error.class}: #{error.message}\n"
      (error.backtrace || []).each do |line|
        error_info << ' ' * 8 + 'from ' + line + "\n"
      end
      error_info
    end

    def assume_array(obj)
      return obj if obj.is_a? Array
      [obj]
    end

    def assume_proc(value)
      return value if value.is_a? Proc
      proc { value }
    end
  end
end
