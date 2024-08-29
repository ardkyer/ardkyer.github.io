module Jekyll
    class RelativeImageUrl < Liquid::Tag
      def initialize(tag_name, markup, tokens)
        super
        @markup = markup.strip
      end
  
      def render(context)
        site = context.registers[:site]
        page = context.registers[:page]
        
        image_path = @markup.gsub("../", "/")
        "#{site.baseurl}#{image_path}"
      end
    end
  end
  
  Liquid::Template.register_tag('relative_image_url', Jekyll::RelativeImageUrl)