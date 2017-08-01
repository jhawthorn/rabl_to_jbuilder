require "sexp_processor"
require "composite_sexp_processor"
require "active_support/inflector"

module RablToJbuilder
  class Transformer < CompositeSexpProcessor
    def initialize(*args)
      super()

      [
        ChildTransformer,
        NodeTransformer,
        SimpleTransformer
      ].each do |subclass|
        self << subclass.new(*args)
      end
    end
  end

  class Base < SexpProcessor
    def initialize(object)
      super()
      @object = object
    end

    private

    def json
      s(:lvar, :json)
    end

    def empty
      # HACK!
      s(:lvar, '')
    end
  end

  class ChildTransformer < Base
    def rewrite_iter(exp)
      if exp[1][0..2] == s(:call, nil, :child)
        child = exp[1]
        block = exp[3]

        key, attribute = nil, nil

        if child[3][0] == :lit
          key = child[3][1]
          attribute = s(:call, @object, key)
        elsif child[3][0] == :hash
          _, attribute, key = child[3][1]
          if attribute[0] == :lit
            attribute = s(:call, @object, attribute[1])
          end
        else
          raise "wtf"
        end

        if plural?(key)
          singular_key = key.to_s.singularize.to_sym
          args = s(:args, singular_key)

          block = Transformer.new(s(:lvar, singular_key)).process(block)

          s(:iter, s(:call, json, key, attribute), args, block)
        else
          args = 0
          block = Transformer.new(attribute).process(block)

          s(:iter, s(:call, json, key), args, block)
        end
      else
        exp
      end
    end

    private

    def plural?(s)
      s = s.to_s
      s.pluralize == s
    end
  end

  class NodeTransformer < Base
    def rewrite_iter(exp)
      if exp[1][0..2] == s(:call, nil, :node)
        node = exp[1]
        args = exp[2]
        block = exp[3]

        if args[0] == :args
          block = block.gsub(s(:lvar, :post), @object)
        elsif args == 0
        else
          raise "wat?"
        end

        s(:iter, s(:call, json, node[3][1]), 0, block)
      else
        exp
      end
    end
  end

  class SimpleTransformer < Base
    def rewrite_call(exp)
      _, target, meth, *args = exp

      return exp unless target.nil?

      if meth == :object
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
