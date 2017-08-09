require "rabl_to_jbuilder/version"
require "rabl_to_jbuilder/transformer"

require 'ruby2ruby'
require 'ruby_parser'

module RablToJbuilder
  def self.convert(rabl, object: nil)
    parser    = RubyParser.new
    ruby2ruby = Ruby2Ruby.new
    root_node = parser.process(rabl)

    return "" unless root_node

    if !object
      match = root_node / Sexp.s(:call, nil, :object, Sexp._)
      object = match[0][3] unless match.empty?

      collection_match = root_node / Sexp.s(:call, nil, :collection, Sexp._)
      if collection_match.any?
        collection = collection_match[0][3]
        raise unless collection[0] == :ivar
        singular_name = collection[1].to_s[1..-1].singularize.to_sym
        root_node = s(:iter, s(:call, s(:call, nil, :json), :array!, collection), s(:args, singular_name), root_node)
        object = s(:lvar, singular_name.to_sym)
      end
    end

    transformer = Transformer.new(object)
    converted = transformer.process(root_node)

    ruby2ruby.process(converted)
  end
end
