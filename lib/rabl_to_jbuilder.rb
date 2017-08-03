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
    end

    transformer = Transformer.new(object)
    converted = transformer.process(root_node)

    ruby2ruby.process(converted)
  end
end
