module Sorge
  class CLI
    module Parser
      module_function

      def parse(args)
        args.map do |o|
          key, val = o.split('=', 2)
          [key.to_sym, parse_value(val)]
        end.to_h
      end

      def parse_value(value)
        case value
        when 'true', 'false'
          value == 'true'
        when /\A\d+\z/
          value.to_i
        when /\A\d+\.\d+\z/
          value.to_f
        when /\A\d{4}-\d{2}-\d{2}\z/
          Date.parse(value)
        when /\A\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}( \d{4})?\z/
          Time.parse(value)
        when /\A(["']).*\1\z/
          value[1..-2]
        else
          value
        end
      end
    end
  end
end
