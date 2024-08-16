source "https://rubygems.org"

# GitHub Pages와 호환되는 jekyll 버전 사용
gem "github-pages", group: :jekyll_plugins

group :jekyll_plugins do
  gem "jekyll-feed", "~> 0.12"
  gem "jekyll-sass-converter", "~> 1.5"
end

# Windows와 JRuby에서 이벤트 시스템 성능 향상을 위한 gem들
platforms :mingw, :x64_mingw, :mswin, :jruby do
  gem "tzinfo", ">= 1", "< 3"
  gem "tzinfo-data"
end

# Windows에서 성능 향상을 위한 gem
gem "wdm", "~> 0.1.1", :platforms => [:mingw, :x64_mingw, :mswin]

# JRuby에서 사용되는 HTTP 파서
gem "http_parser.rb", "~> 0.6.0", :platforms => [:jruby]

# HTTP 서버 (Jekyll 4.0+에서 필요)
gem "webrick", "~> 1.7"