require 'nokogiri'
require 'open-uri'
require 'json'
require 'logger'
require 'fileutils'
require 'uri'

class DataNormalizer
  # Dictionary mapping for locations
  LOCATION_MAP_DICTIONARY = {
    "Munich, DE" => "Munich",
    "München" => "Munich",
    "San Francisco, CA" => "San Francisco",
    "New York, NY" => "New York",
    "London, UK" => "London",
    "Berlin, DE" => "Berlin"
  }.freeze

  def self.normalize_location(raw_location)
    return "Remote" if raw_location.nil? || raw_location.empty?
    
    # Try exact dictionary match first
    return LOCATION_MAP_DICTIONARY[raw_location] if LOCATION_MAP_DICTIONARY.key?(raw_location)
    
    # Otherwise, clean it up a bit (remove common extra terms)
    # E.g., 'Anywhere in the World' -> 'Worldwide'
    loc = raw_location.strip
    loc = "Worldwide" if loc.downcase.include?('anywhere')
    loc
  end

  def self.normalize_salary(raw_salary)
    # E.g. $100k - $120k -> min: 100000, max: 120000
    # $100,000 USD -> min: 100000, max: 100000
    return nil if raw_salary.nil? || raw_salary.empty?
    
    # Extract all numbers matching k or with commas
    # Very basic naive extraction for the prompt's request
    numbers = raw_salary.scan(/(\d+)(k|K|,000)/).map do |match|
      num = match[0].to_i
      num *= 1000 if match[1].downcase == 'k'
      num
    end
    
    return nil if numbers.empty?
    
    min = numbers.min
    max = numbers.max
    
    { min: min, max: max }
  end
end

class RubyJobScout
  
  def initialize
    @storage_file = "../frontend/public/jobs.json"
    @logger = Logger.new($stdout)
    @logger.level = Logger::INFO
    @jobs = load_jobs
  end

  def run
    @logger.info("Starting RubyJobScout Crawler...")
    fetch_jobs
    @logger.info("Finished crawling. Total jobs stored: #{@jobs.size}")
  end

  private

  def load_jobs
    return [] unless File.exist?(@storage_file)
    JSON.parse(File.read(@storage_file), symbolize_names: true)
  rescue JSON::ParserError
    @logger.error("Failed to parse #{@storage_file}. Returning empty array.")
    []
  end
  
  def save_jobs
    File.write(@storage_file, JSON.pretty_generate(@jobs))
    @logger.info("Saved #{@jobs.size} jobs to #{@storage_file}")
  end
  
  def fetch_jobs
    url = 'https://weworkremotely.com/categories/remote-programming-jobs.rss'
    @logger.info("Fetching jobs from #{url}...")
    
    headers = {
      "User-Agent" => "RubyJobScout Bot/1.0 (+https://github.com/myusername/rubyjobscout)"
    }
    
    begin
      xml = URI.open(url, headers)
      doc = Nokogiri::XML(xml)
      
      doc.xpath('//item').each do |item_node|
        # WWR RSS Title format: "Company Name: Job Title"
        full_title = item_node.at_xpath('title')&.text.to_s.strip
        company_name, job_title = full_title.split(': ', 2)
        
        # Fallbacks in case splitting failed
        job_title ||= full_title
        company_name ||= "Unknown"
        
        location_raw = item_node.at_xpath('region')&.text.to_s.strip
        job_url = item_node.at_xpath('link')&.text.to_s.strip
        description = item_node.at_xpath('description')&.text.to_s.strip
        
        # WWR RSS often hides explicit salary in description tags
        salary_str = extract_salary(description)
        
        process_job(
          url: job_url,
          title: job_title,
          company: company_name,
          location: location_raw,
          salary_raw: salary_str,
          description: description,
          source: 'We Work Remotely'
        )
      end
      
      save_jobs
    rescue StandardError => e
      @logger.error("Error fetching jobs: #{e.message}")
    end
  end

  def extract_salary(text)
    # Match things like $50K, $250,000 - $280,000, $100-$200
    match = text.scan(/\$[\d,]+[kK]?\s*(?:[-–to]+\s*\$[\d,]+[kK]?)?/).first
    match || ""
  end

  def process_job(job_data)
    # Apply DataNormalizer
    job_data[:location] = DataNormalizer.normalize_location(job_data[:location])
    
    # Store normalized salary alongside raw
    job_data[:salary_normalized] = DataNormalizer.normalize_salary(job_data[:salary_raw])
    
    existing_job = @jobs.find { |j| j[:url] == job_data[:url] }
    
    if existing_job
      existing_job[:last_seen_at] = Time.now.utc.iso8601
      # Update location/salary if they changed
      existing_job[:location] = job_data[:location]
      existing_job[:salary_normalized] = job_data[:salary_normalized]
      @logger.debug("Updated timestamp for existing job: #{job_data[:title]}")
    else
      job_data[:created_at] = Time.now.utc.iso8601
      job_data[:last_seen_at] = Time.now.utc.iso8601
      @jobs << job_data
      @logger.info("Added new job: #{job_data[:title]} at #{job_data[:company]}")
    end
  end
end

if __FILE__ == $0
  RubyJobScout.new.run
end
