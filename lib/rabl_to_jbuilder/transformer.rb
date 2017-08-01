require "sexp_processor"
require "composite_sexp_processor"

module RablToJbuilder
  class Transformer < CompositeSexpProcessor
    def initialize
      super()

      self << IterTransformer.new
      self << CallTransformer.new
    end
  end

  module Helpers
    private

    def json
      s(:lvar, :json)
    end

    def empty
      # HACK!
      s(:lvar, '')
    end
  end

  class IterTransformer < SexpProcessor
    include Helpers

    def initialize
      super()
      @debug.update(iter: true, call: true)
    end

    def rewrite_iter(exp)
      if exp[1][0..2] == s(:call, nil, :child)
        exp # FIXME
      else
        exp
      end
    end
  end

  class CallTransformer < SexpProcessor
    include Helpers

    def initialize(object = nil)
      super()

      @object = object
      @debug.update(iter: true, call: true)
    end

    def rewrite_iter(exp)
      if exp[1][0..2] == s(:call, nil, :node)
        s(exp[0], nil, exp[4])
      else
        exp
      end
    end

    def rewrite_call(exp)
      _, target, meth, *args = exp

      return exp unless target.nil?

      if meth == :object
        @object = args[0]
        empty
      elsif meth == :attributes
        raise "called attributes before declaring `object` or `collection`" unless @object
        s(:call, json, nil, @object, *args)
      elsif meth == :node
        raise unless args[0][0] == :lit
        key = args[0][1]
        s(:call, json, key)
      else
        exp
      end
    end
  end
end
