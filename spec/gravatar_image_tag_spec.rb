# frozen_string_literal: true

require File.dirname(__FILE__) + '/test_helper'

require 'gravatar_image_tag'

ActionView::Base.include GravatarImageTag

describe GravatarImageTag do
  email                 = 'mdeering@mdeering.com'
  md5                   = '4da9ad2bd4a2d1ce3c428e32c423588a'
  default_filetype      = :gif
  default_image         = 'http://mdeering.com/images/default_gravatar.png'
  default_image_escaped = 'http%3A%2F%2Fmdeering.com%2Fimages%2Fdefault_gravatar.png'
  default_rating        = 'x'
  default_size          = 50
  other_image           = 'http://mdeering.com/images/other_gravatar.png'
  other_image_escaped   = 'http%3A%2F%2Fmdeering.com%2Fimages%2Fother_gravatar.png'
  secure                = false

  view = ActionView::Base.new

  context '#gravatar_image_tag' do
    {
      { gravatar_id: md5 } => {},
      { gravatar_id: md5 } => { gravatar: { rating: 'x' } },
      { gravatar_id: md5, size: 30 } => { gravatar: { size: 30 } },
      { gravatar_id: md5, default: other_image_escaped } => { gravatar: { default: other_image } },
      { gravatar_id: md5, default: other_image_escaped, size: 30 } => { gravatar: { default: other_image, size: 30 } }
    }.each do |params, options|
      it "#gravatar_image_tag should create the provided url with the provided options #{options}" do
        view = ActionView::Base.new
        image_tag = view.gravatar_image_tag(email, options)
        expect(image_tag.include?(params.delete(:gravatar_id).to_s)).to be_truthy
        expect(params.all? { |key, value| image_tag.include?("#{key}=#{value}") }).to be_truthy
      end
    end

    {
      default_gravatar_image: default_image,
      default_gravatar_filetype: default_filetype,
      default_gravatar_rating: default_rating,
      default_gravatar_size: default_size,
      secure_gravatar: secure
    }.each do |singleton_variable, value|
      it "should give a deprication warning for assigning to #{singleton_variable} and passthrough to set the new variable" do
        expect(ActionView::Base).to receive(:warn)
        ActionView::Base.send("#{singleton_variable}=", value)
        GravatarImageTag.configuration.default_image == value if singleton_variable == :default_gravatar_image
        GravatarImageTag.configuration.filetype      == value if singleton_variable == :default_gravatar_filetype
        GravatarImageTag.configuration.rating        == value if singleton_variable == :default_gravatar_rating
        GravatarImageTag.configuration.size          == value if singleton_variable == :default_gravatar_size
        GravatarImageTag.configuration.secure        == value if singleton_variable == :secure_gravatar
      end
    end

    # Now that the defaults are set...
    {
      { gravatar_id: md5, size: default_size, default: default_image_escaped } => {},
      { gravatar_id: md5, size: 30, default: default_image_escaped } => { gravatar: { size: 30 } },
      { gravatar_id: md5, size: default_size, default: other_image_escaped } => { gravatar: { default: other_image } },
      { gravatar_id: md5, size: 30, default: other_image_escaped } => { gravatar: { default: other_image, size: 30 } }
    }.each do |params, options|
      it "#gravatar_image_tag #{params} should create the provided url when defaults have been set with the provided options #{options}" do
        view = ActionView::Base.new
        image_tag = view.gravatar_image_tag(email, options)
        expect(image_tag.include?("#{params.delete(:gravatar_id)}.#{default_filetype}")).to be_truthy
        expect(params.all? { |key, value| image_tag.include?("#{key}=#{value}") }).to be_truthy
      end
    end

    it 'should request the gravatar image from the non-secure server when the https: false option is given' do
      expect(!!view.gravatar_image_tag(email, { gravatar: { secure: false } }).match(%r{^https://secure.gravatar.com/avatar/})).to be_falsey
    end

    it 'should request the gravatar image from the secure server when the https: true option is given' do
      expect(!!view.gravatar_image_tag(email, { gravatar: { secure: true } }).match(%r{src="https://secure.gravatar.com/avatar/})).to be_truthy
    end

    it 'should set the image tags height and width to avoid the page going all jiggy (technical term) when loading a page with lots of Gravatars' do
      GravatarImageTag.configure { |c| c.size = 30 }
      expect(!!view.gravatar_image_tag(email).match(/height="30"/)).to be_truthy
      expect(!!view.gravatar_image_tag(email).match(/width="30"/)).to  be_truthy
    end

    it 'should set the image tags height and width attributes to 80px (gravatars default) if no size is given.' do
      GravatarImageTag.configure { |c| c.size = nil }
      expect(!!view.gravatar_image_tag(email).match(/height="80"/)).to be_truthy
      expect(!!view.gravatar_image_tag(email).match(/width="80"/)).to  be_truthy
    end

    it 'should set the image tags height and width attributes from the overrides on the size' do
      GravatarImageTag.configure { |c| c.size = 120 }
      expect(!!view.gravatar_image_tag(email, gravatar: { size: 45 }).match(/height="45"/)).to be_truthy
      expect(!!view.gravatar_image_tag(email, gravatar: { size: 75 }).match(/width="75"/)).to  be_truthy
    end

    it 'should not include the height and width attributes on the image tag if it is turned off in the configuration' do
      GravatarImageTag.configure { |c| c.include_size_attributes = false }
      expect(!!view.gravatar_image_tag(email).match(/height=/)).to be_falsey
      expect(!!view.gravatar_image_tag(email).match(/width=/)).to  be_falsey
    end

    it 'GravatarImageTag#gravitar_id should not error out when email is nil' do
      expect { GravatarImageTag.gravatar_id(nil) }.to_not raise_error
    end

    it 'should normalize the email to Gravatar standards (http://en.gravatar.com/site/implement/hash/)' do
      expect(view.gravatar_image_tag(" camelCaseEmail@example.com\t\n")).to eq(view.gravatar_image_tag('camelcaseemail@example.com'))
    end
  end

  context '#gravatar_image_url' do
    it '#gravatar_image_url should return a gravatar URL' do
      expect(!!view.gravatar_image_url(email).match(%r{^http://gravatar.com/avatar/})).to be_truthy
    end

    it '#gravatar_image_url should set the email as an md5 digest' do
      expect(!!view.gravatar_image_url(email).match("http:\/\/gravatar.com\/avatar\/#{md5}")).to be_truthy
    end

    it '#gravatar_image_url should set the default_image' do
      expect(!!view.gravatar_image_url(email).include?("default=#{default_image_escaped}")).to be_truthy
    end

    it '#gravatar_image_url should set the filetype' do
      expect(!!view.gravatar_image_url(email, filetype: :png).match("http:\/\/gravatar.com\/avatar\/#{md5}.png")).to be_truthy
    end

    it '#gravatar_image_url should set the rating' do
      expect(!!view.gravatar_image_url(email, rating: 'pg').include?('rating=pg')).to be_truthy
    end

    it '#gravatar_image_url should set the size' do
      expect(!!view.gravatar_image_url(email, size: 100).match(/size=100/)).to be_truthy
    end

    it '#gravatar_image_url should use http protocol when the https: false option is given' do
      expect(!!view.gravatar_image_url(email, secure: false).match("^http:\/\/gravatar.com\/avatar\/")).to be_truthy
    end

    it '#gravatar_image_url should use https protocol when the https: true option is given' do
      expect(!!view.gravatar_image_url(email, secure: true).match("^https:\/\/secure.gravatar.com\/avatar\/")).to be_truthy
    end
  end
end
