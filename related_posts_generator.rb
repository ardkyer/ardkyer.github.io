#!/usr/bin/env ruby
require 'json'
require 'fileutils'
require 'yaml'
require 'net/http'
require 'uri'
require 'base64'

class RelatedPostsGenerator
  API_KEY = ENV['AI_API_KEY'] # 환경 변수에서 API 키 가져오기
  API_ENDPOINT = "https://api.anthropic.com/v1/messages" # Claude API 엔드포인트
  
  def initialize(posts_dir = "_posts", output_dir = "_data")
    @posts_dir = posts_dir
    @output_dir = output_dir
    @all_posts = []
    @related_posts = {}
    
    # 출력 디렉토리가 없으면 생성
    FileUtils.mkdir_p(@output_dir) unless Dir.exist?(@output_dir)
  end
  
  # 모든 게시물 읽기
  def read_all_posts
    puts "모든 게시물 읽는 중..."
    
    Dir.glob(File.join(@posts_dir, "**/*.md")).each do |file|
      content = File.read(file)
      
      # YAML Front Matter 파싱
      if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
        front_matter = YAML.safe_load($1, permitted_classes: [Date, Time])
        
        # 게시물 메타데이터와 내용 추출
        title = front_matter["title"] || "Untitled"
        categories = front_matter["categories"] || []
        tags = front_matter["tags"] || []
        
        # 실제 콘텐츠 (YAML Front Matter 이후)
        body = content.sub(/\A---\s*\n.*?\n---\s*\n/m, '')
        summary = body.strip.split(/\n+/).first(3).join(" ").gsub(/\s+/, ' ').strip
        
        # 파일 이름에서 날짜와 슬러그 추출
        filename = File.basename(file, ".*")
        date = filename[0..9] if filename =~ /^\d{4}-\d{2}-\d{2}/
        slug = filename[11..-1] if date
        
        # 게시물 URL 생성
        url = date ? "/#{date.gsub('-', '/')}/#{slug}" : "/#{filename}"
        
        @all_posts << {
          title: title,
          url: url,
          categories: categories,
          tags: tags,
          summary: summary,
          content: body[0..5000], # 처리를 위해 내용 제한
          file: file
        }
      end
    end
    
    puts "총 #{@all_posts.size}개의 게시물을 찾았습니다."
  end
  
  # AI API를 사용하여 관련 게시물 찾기
  def find_related_posts
    puts "게시물 간 관련성 분석 중..."
    
    total = @all_posts.size
    @all_posts.each_with_index do |post, index|
      puts "[#{index + 1}/#{total}] '#{post[:title]}' 관련 게시물 찾는 중..."
      
      # AI에 보낼 프롬프트 생성
      prompt = create_prompt(post)
      
      # API 호출하여 관련 게시물 찾기
      related = call_ai_api(prompt, post)
      
      # 결과 저장
      @related_posts[post[:url]] = related
      
      # API 요청 간 간격 두기
      sleep(1) unless index == total - 1
    end
  end
  
  # AI 프롬프트 생성
  def create_prompt(current_post)
    # 다른 모든 게시물의 제목과 요약 정보 수집
    other_posts = @all_posts.reject { |p| p[:url] == current_post[:url] }.map do |p|
      "제목: #{p[:title]}\nURL: #{p[:url]}\n요약: #{p[:summary]}\n카테고리: #{p[:categories].join(', ')}\n태그: #{p[:tags].join(', ')}"
    end
    
    # 프롬프트 생성
    <<~PROMPT
    현재 게시물:
    제목: #{current_post[:title]}
    요약: #{current_post[:summary]}
    카테고리: #{current_post[:categories].join(', ')}
    태그: #{current_post[:tags].join(', ')}
    
    다음은 블로그의 다른 게시물 목록입니다:
    
    #{other_posts.join("\n\n")}
    
    위 게시물 목록에서 현재 게시물과 가장 관련성이 높은 게시물 3-5개를 찾아주세요. 
    콘텐츠, 카테고리, 태그의 유사성을 기반으로 판단해주세요. 결과는 다음 JSON 형식으로 반환해주세요:
    
    [
      {"url": "/게시물URL", "title": "게시물 제목", "reason": "관련성에 대한 간단한 설명"},
      ...
    ]
    
    JSON 형식만 반환하고 다른 설명은 포함하지 마세요.
    PROMPT
  end
  
  # AI API 호출
  def call_ai_api(prompt, current_post)
    return mock_api_call(current_post) if API_KEY.nil? || API_KEY.empty?
    
    uri = URI.parse(API_ENDPOINT)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    
    request = Net::HTTP::Post.new(uri.path, {
      'Content-Type' => 'application/json',
      'x-api-key' => API_KEY,
      'anthropic-version' => '2023-06-01'
    })
    
    request.body = {
      model: "claude-3-opus-20240229",
      max_tokens: 1000,
      messages: [
        { role: "user", content: prompt }
      ]
    }.to_json
    
    begin
      response = http.request(request)
      
      if response.code == "200"
        result = JSON.parse(response.body)
        content = result["content"].first["text"]
        
        # JSON 부분만 추출
        if content =~ /\[.*\]/m
          json_str = content.match(/\[.*\]/m)[0]
          return JSON.parse(json_str)
        else
          puts "API 응답에서 JSON을 찾을 수 없습니다: #{content}"
          return []
        end
      else
        puts "API 오류: #{response.code} - #{response.body}"
        return mock_api_call(current_post)
      end
    rescue => e
      puts "API 호출 중 예외 발생: #{e.message}"
      return mock_api_call(current_post)
    end
  end
  
  # API 키가 없을 경우 임시 모의 결과 생성
  def mock_api_call(current_post)
    puts "API 키 없음 - 태그와 카테고리 기반으로 관련 게시물 찾는 중..."
    
    # 간단한 관련성 점수 계산
    scored_posts = @all_posts.reject { |p| p[:url] == current_post[:url] }.map do |post|
      # 태그 유사성
      common_tags = (current_post[:tags] & post[:tags]).size
      tag_score = current_post[:tags].empty? ? 0 : common_tags.to_f / current_post[:tags].size
      
      # 카테고리 유사성
      common_cats = (current_post[:categories] & post[:categories]).size
      cat_score = current_post[:categories].empty? ? 0 : common_cats.to_f / current_post[:categories].size
      
      # 종합 점수
      score = (tag_score * 0.6) + (cat_score * 0.4)
      
      {
        post: post,
        score: score
      }
    end
    
    # 점수에 따라 정렬하고 상위 5개 추출
    top_related = scored_posts.sort_by { |item| -item[:score] }.first(5)
    
    # 결과 변환
    top_related.map do |item|
      {
        "url" => item[:post][:url],
        "title" => item[:post][:title],
        "reason" => "태그와 카테고리 유사성"
      }
    end
  end
  
  # 결과를 JSON으로 저장
  def save_results
    puts "관련 게시물 데이터 저장 중..."
    
    output_file = File.join(@output_dir, "related_posts.json")
    File.write(output_file, JSON.pretty_generate(@related_posts))
    
    puts "저장 완료: #{output_file}"
  end
  
  # 전체 프로세스 실행
  def generate
    read_all_posts
    find_related_posts
    save_results
    puts "관련 게시물 생성 완료!"
  end
end

# 스크립트 실행
if __FILE__ == $0
  generator = RelatedPostsGenerator.new
  generator.generate
end