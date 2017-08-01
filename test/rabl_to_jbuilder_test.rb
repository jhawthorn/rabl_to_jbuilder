require 'test_helper'

class RablToJbuilderTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::RablToJbuilder::VERSION
  end

  def convert(rabl)
    RablToJbuilder.convert(rabl)
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
      json.read { @post.read_by?(@user) }
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

    puts convert(rabl)
  end
end
