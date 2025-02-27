# frozen_string_literal: true

module GravatarImageTag
  class << self
    attr_accessor :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end

  class Configuration
    attr_accessor :default_image, :filetype, :include_size_attributes,
                  :rating, :size, :secure

    def initialize
      @include_size_attributes = true
    end
  end

  def self.included(base)
    GravatarImageTag.configure { |_c| nil }
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end

  module ClassMethods
    def default_gravatar_filetype=(value)
      warn 'DEPRECATION WARNING: configuration of filetype= through this method is deprecated! Use the block configuration instead. http://github.com/mdeering/gravatar_image_tag'
      GravatarImageTag.configure do |c|
        c.filetype = value
      end
    end

    def default_gravatar_image=(value)
      warn 'DEPRECATION WARNING: configuration of default_gravatar_image= through this method is deprecated! Use the block configuration instead. http://github.com/mdeering/gravatar_image_tag'
      GravatarImageTag.configure do |c|
        c.default_image = value
      end
    end

    def default_gravatar_rating=(value)
      warn 'DEPRECATION WARNING: configuration of default_gravatar_rating= through this method is deprecated! Use the block configuration instead. http://github.com/mdeering/gravatar_image_tag'
      GravatarImageTag.configure do |c|
        c.rating = value
      end
    end

    def default_gravatar_size=(value)
      warn 'DEPRECATION WARNING: configuration of default_gravatar_size= through this method is deprecated! Use the block configuration instead. http://github.com/mdeering/gravatar_image_tag'
      GravatarImageTag.configure do |c|
        c.size = value
      end
    end

    def secure_gravatar=(value)
      warn 'DEPRECATION WARNING: configuration of secure_gravatar= through this method is deprecated! Use the block configuration instead. http://github.com/mdeering/gravatar_image_tag'
      GravatarImageTag.configure do |c|
        c.secure = value
      end
    end
  end

  module InstanceMethods
    def gravatar_image_tag(email, options = {})
      gravatar_overrides = options.delete(:gravatar)
      options[:src] = gravatar_image_url(email, gravatar_overrides)
      options[:alt] ||= 'Gravatar'
      if GravatarImageTag.configuration.include_size_attributes
        size = GravatarImageTag.gravatar_options(gravatar_overrides)[:size] || 80
        options[:height] = options[:width] = size.to_s
      end

      # Patch submitted to rails to allow image_tag here
      # https://rails.lighthouseapp.com/projects/8994/tickets/2878
      tag 'img', options, false, false
    end

    def gravatar_image_url(email, gravatar_overrides = {})
      email = email.strip.downcase if email.is_a? String
      GravatarImageTag.gravatar_url(email, gravatar_overrides)
    end
  end

  def self.gravatar_url(email, overrides = {})
    gravatar_params = gravatar_options(overrides || {})
    url_base        = gravatar_url_base(gravatar_params.delete(:secure))
    hash            = gravatar_id(email, gravatar_params.delete(:filetype))
    url_params      = url_params(gravatar_params)
    "#{url_base}/#{hash}#{url_params}"
  end

  def self.gravatar_options(overrides = {})
    {
      default: GravatarImageTag.configuration.default_image,
      filetype: GravatarImageTag.configuration.filetype,
      rating: GravatarImageTag.configuration.rating,
      secure: GravatarImageTag.configuration.secure,
      size: GravatarImageTag.configuration.size
    }.merge(overrides || {}).delete_if { |_key, value| value.nil? }
  end

  def self.gravatar_url_base(secure = false)
    'http' + (!!secure ? 's://secure.' : '://') + 'gravatar.com/avatar'
  end

  def self.gravatar_id(email, filetype = nil)
    return nil unless email

    "#{Digest::MD5.hexdigest(email)}#{".#{filetype}" unless filetype.nil?}"
  end

  def self.url_params(gravatar_params)
    return nil if gravatar_params.keys.size.zero?

    array = gravatar_params.map { |k, v| "#{k}=#{value_cleaner(v)}" }
    "?#{array.join('&')}"
  end

  def self.value_cleaner(value)
    value = value.to_s
    URI.encode_www_form_component(value)
  end
end

ActionView::Base.include GravatarImageTag if defined?(ActionView::Base)
