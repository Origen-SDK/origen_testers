module OrigenTesters
  class SiteConfig
    def initialize
      @configs ||= Origen.site_config.origen_testers || {}
    end

    def method_missing(method, *args, &block)
      method = method.to_s
      if method =~ /(.*)!$/
        method = Regexp.last_match(1)
        must_be_present = true
      end
      val = find_val(method)
      if must_be_present && val.nil?
        puts "No value assigned for origen_testers site_config attribute '#{method}'"
        puts
        fail 'Missing site_config value!'
      end
      define_singleton_method(method) do
        val
      end
      val
    end

    private

    def find_val(val, options = {})
      config = @configs.find { |c| c.key?(val) }
      config ? config[val] : nil
    end
  end

  def self.site_config
    @site_config ||= SiteConfig.new
  end
end
