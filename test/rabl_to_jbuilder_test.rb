require 'test_helper'

class RablToJbuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RablToJbuilder::VERSION
  end

  def convert(rabl)
    RablToJbuilder.convert(rabl).strip
  end

  def test_empty
    assert_equal "", convert("")
  end

  def test_no_rabl
    assert_equal "yolo", convert("yolo")
  end

  def test_extends
    assert_equal %q{json.partial!("foo/bar")}, convert(%q{extends "foo/bar"})
  end

  def test_extends_passes_object
    rabl = <<~RABL
      object @foo
      extends "foo/bar"
    RABL
    assert_equal %q{json.partial!("foo/bar", :foo => (@foo))}, convert(rabl)
  end

  def test_convert_simple_rabl
    rabl = <<~RABL
      #foo
      object @post
      attributes :id, :title, :subject
      child(:user) { attributes :full_name }
      node(:read) { |post| post.read_by?(@user) }
    RABL

    expected = <<~JBUILDER
      json.(@post, :id, :title, :subject)
      json.user { json.(@post.user, :full_name) }
      json.read(@post.read_by?(@user))
    JBUILDER

    assert_equal expected.strip, convert(rabl).strip
  end

  # Taken from https://gist.github.com/awesome/2505134
  def test_more_complex
    rabl = <<~RABL
      object @message

      node(:content) { format_content(@message.content) }
      attributes :created_at, :updated_at

      child @message.creator => :author do
        node(:name) { |a| a.name.familiar }
        node(:email_address) { |a| a.email_address_with_name }
        node(:url) { |a| url_for(a, format: :json) }
      end

      if current_user.admin?
        node(:visitors) { calculate_visitors(@message) } 
      end

      child :comments do
        attributes :content, :created_at
      end

      child :attachments do
        attributes :filename
        node(:url) { url_for(attachment) }
      end
    RABL

    expected = <<~JBUILDER
      json.content(format_content(@message.content))
      json.(@message, :created_at, :updated_at)
      json.author do
        json.name(@message.creator.name.familiar)
        json.email_address(@message.creator.email_address_with_name)
        json.url(url_for(@message.creator, :format => :json))
      end
      json.visitors(calculate_visitors(@message)) if current_user.admin?
      json.comments(@message.comments) do |comment|
        json.(comment, :content, :created_at)
      end
      json.attachments(@message.attachments) do |attachment|
        json.(attachment, :filename)
        json.url(url_for(attachment))
      end
    JBUILDER

    assert_equal expected.strip, convert(rabl).strip
  end

  def test_child_hash_both_symbols
    rabl = <<~RABL
      object @post

      child :user => :author do
        attributes :name
      end
    RABL

    expected = <<~JBUILDER
      json.author { json.(@post.user, :name) }
    JBUILDER

    assert_equal expected.strip, convert(rabl).strip
  end

  def test_attribute
    rabl = <<~RABL
      object @post

      attribute :title
    RABL

    expected = <<~JBUILDER
      json.(@post, :title)
    JBUILDER

    assert_equal expected.strip, convert(rabl).strip
  end
end
