require "rabl_to_jbuilder/version"
require "rabl_to_jbuilder/transformer"

require 'ruby2ruby'
require 'ruby_parser'

module RablToJbuilder
  def self.convert(rabl)
    parser    = RubyParser.new
    ruby2ruby = Ruby2Ruby.new
    root_node = parser.process(rabl)

    puts
    puts "rabl"
    puts '='*20
    pp rabl
    puts
    puts "sexp"
    puts '='*20
    pp root_node
    puts

    match = root_node / Sexp.s(:call, nil, :object, Sexp._)
    object = match && match[0][3]

    transformer = Transformer.new(object)
    converted = transformer.process(root_node)

    ruby2ruby.process(converted)
  end
end
