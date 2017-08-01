require 'test_helper'

class RablToJbuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RablToJbuilder::VERSION
  end

  def test_convert_simple_rabl
    rabl = <<~RABL
      #foo
      object @post
      attributes :id, :title, :subject
      child(:user) { attributes :full_name }
      node(:read) { |post| post.read_by?(@user) }
    RABL

    jbuilder = RablToJbuilder.convert(rabl)

    puts jbuilder
  end
end
