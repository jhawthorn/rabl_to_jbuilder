require "rabl_to_jbuilder/version"
require "rabl_to_jbuilder/transformer"

require 'ruby2ruby'
require 'ruby_parser'

module RablToJbuilder
  def self.convert(rabl)
    parser    = RubyParser.new
    ruby2ruby = Ruby2Ruby.new
    root_node = parser.process(rabl)
    transformer = Transformer.new

    ruby2ruby.process(transformer.process(root_node))
  end
end
