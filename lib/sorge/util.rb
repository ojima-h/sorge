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
  end
end
