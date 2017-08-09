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
    def process_iter(exp)
      exp.shift # :iter
      call = exp.shift
      args = exp.shift
      block = exp.shift

      if call[0..2] == s(:call, nil, :child)
        child = call

        key, attribute = nil, nil

        if child[3][0] == :lit
          key = child[3][1]
          attribute = s(:call, @object, key)
        elsif child[3][0] == :hash
          _, attribute, key = child[3]
          if attribute[0] == :lit
            attribute = s(:call, @object, attribute[1])
          end

          raise unless key[0] == :lit
          key = key[1]
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
      elsif call[0..2] == s(:call, nil, :glue)
        raise unless call[3][0] == :lit
        attribute = call[3][1]
        object = s(:call, @object, attribute)
        block = Transformer.new(object).process(block)
        block
      else
        s(:iter, call, args, block)
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
          block = block.gsub(s(:lvar, args[1]), @object)
        elsif args == 0
        else
          raise "wat?"
        end

        key = node[3]
        if key[0] == :lit
          s(:call, json, key[1], block)
        else
          s(:call, json, :set!, key, block)
        end
      else
        exp
      end
    end
  end

  class SimpleTransformer < Base
    def rewrite_call(exp)
      _, target, meth, *args = exp

      return exp unless target.nil?

      if meth == :object || meth == :collection
        empty
      elsif meth == :attributes
        raise "called attributes before declaring `object` or `collection`" unless @object
        s(:call, json, nil, @object, *args)
      elsif meth == :attribute
        raise "called attributes before declaring `object` or `collection`" unless @object
        # FIXME: options hash and conditions
        s(:call, json, args[0][1], s(:call, @object, args[0][1]))
      elsif meth == :extends
        if @object
          raise "extends must take a string" unless args[0][0] == :str
          template = args[0][1]
          variable = File.basename(File.dirname(args[0][1])).singularize

          locals_hash = s(:hash, s(:lit, variable.to_sym), @object)

          s(:call, json, :partial!, args[0], locals_hash)
        else
          s(:call, json, :partial!, args[0])
        end
      else
        exp
      end
    end
  end
end
