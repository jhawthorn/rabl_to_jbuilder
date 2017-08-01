require 'sexp_processor'

module RablToJbuilder
  class Transformer < SexpProcessor
    def initialize
      super
    end

    def rewrite_call(exp)
      _, target, meth, *args = exp

      return exp unless target.nil?

      if meth == :object
        @object = args[0]
        return empty
      elsif meth == :attributes
        raise "called attributes before declaring `object` or `collection`" unless defined?(@object)
        return s(:call, json, :extract!, @object, *args)
      elsif meth == :node
        raise unless args[0][0] == :lit
        key = args[0][1]
        return s(:call, json, key)
      end

      p exp
      exp
    end

    private

    def json
      s(:lvar, :json)
    end

    def empty
      # hack!
      s(:lvar, '')
    end
  end
end
