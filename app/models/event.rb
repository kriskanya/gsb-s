class Event < ApplicationRecord
  STATES = ['Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming']
  STATES_ABBR = ['AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY']

  def self.to_csv_location_only
    require 'json'
    CSV.generate do |csv|
      csv << [ 
        'id',
        'title',
        'location',
        'location_name',
        'location_street',
        'location_city',
        'location_state',
        'location_zip'
      ]  
      all.each do |event|  
        csv << [event.id, 
          event.title,
          event.location, 
          event.location_name,
          event.location_street,
          event.location_city,
          event.location_state,
          event.location_zip]
        end
      end
  end

  def self.to_csv
    require 'json'
    CSV.generate do |csv|
      csv << [ 
        'id',
        'Title',
        'General Admission',
        'Saturday Hours',
        'Sunday Hours',
        'Table Cost',
        'description',
        'dates',
        'rating', 
        'city', 
        'state', 
        'hours', 
        'promoter',
        'organizer_name',
        'organizer_email',
        'organizer_contact',
        'organizer_phone',
        'location',
        'location_name',
        'location_street',
        'location_city',
        'location_state',
        'location_zip',
        'created_at', 
        'updated_at', 
        'state_full',
        'slug',
        'vendor_info',
        'vendor_info_0',
        'vendor_info_1',
        'vendor_info_2',
        'vendor_info_3',
        'vendor_info_4'
       ]
      all.each do |event|
        vendor_info = event.vendor_info_to_array
        promoter = JSON.parse(event.promoter.gsub('=>', ':').gsub('nil', 'null'))
        event_dates = JSON.parse(event.dates)
        event_dates.each_with_index do |date, index|
          csv << [event.id, 
                  event.title, 
                  event.admission,
                  event.parse_saturday(),
                  event.parse_sunday(),
                  event.vendor_info,
                  event.description, 
                  date,
                  event.rating, 
                  event.city, 
                  event.state, 
                  event.hours, 
                  event.promoter, 
                  promoter['organization_name'],
                  promoter['organization_contact_email'],
                  promoter['organization_contact_name'],
                  promoter['organization_contact_phone'],
                  event.location, 
                  event.location_name,
                  event.location_street,
                  event.location_city,
                  event.location_state,
                  event.location_zip,
                  event.created_at, 
                  event.updated_at, 
                  event.state_full,
                  event.get_slug(index),
                  event.vendor_info, 
                  vendor_info[0] || '',
                  vendor_info[1] || '',
                  vendor_info[2] || '',
                  vendor_info[3] || '',
                  vendor_info[4] || ''
                ]
        end
      end
    end
  end

  def vendor_info_to_array
    return JSON.parse(vendor_info)
  end

  def get_slug(index) 
    title = self.title.downcase().gsub(' ', '-').gsub('\'', '')
    return title + '-' + (index + 1).to_s()
  end

  def parse_saturday()
    require 'json'
    s = JSON.parse(self.hours.gsub(':day_of_week', '"day_of_week"').gsub(':hours', '"hours"').gsub('=>', ':').gsub('nil', 'null'))
    if (s.length > 0)
      return s[0]['hours']
    end
  end

  def parse_sunday()
    s = JSON.parse(self.hours.gsub(':day_of_week', '"day_of_week"').gsub(':hours', '"hours"').gsub('=>', ':').gsub('nil', 'null'))
    if (s.length > 0)
      return s[0]['hours']
    end
  end

  def start(states_selected = nil)
    if (states_selected)
      scrape(states_selected)
    end
  end

  def scrape(states_selected)
    gun_show_data = []
    get_all_gunshow_titles(states_selected).each do |gun_show_title|
      new_record = get_individual_gun_show_data(gun_show_title)
      puts gun_show_title
      if (!new_record.nil? && gun_show_data.select { |d| d[:title] == new_record[:title] && d[:location] == new_record[:location] }.length == 0)
        gun_show_data << new_record
        create_record(new_record)
      end
    end 
  end

  def get_all_gunshow_titles(states_selected)
    require 'open-uri'
    gun_show_titles = []
    states_selected.each do |us_state|
      us_state = us_state.gsub(' ', '-').downcase
      url_string = "https://gunshowtrader.com/gunshows/#{us_state}/"
      
      if (url_exists(url_string))
        doc = Nokogiri::HTML(open(url_string).read)
        doc.css('a.event-link').each do |item|
          gun_show_titles << item.attr('href').split('gun-shows/', 2)[1].gsub('/', '')
        end
      end
    end
    # gun_show_titles = ['kankakee-gun-sportsman-show', 'kankakee-gun-sportsman-show', 'kankakee-gun-sportsman-show','kankakee-gun-sportsman-show','kankakee-gun-sportsman-show','kankakee-gun-sportsman-show']
    return gun_show_titles
  end

  def url_exists(url)
    require 'net/http'
    url = URI.parse(url)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = (url.scheme == 'https')
    path = url.path if url.path.present?
    res = req.request_head(path || '/')
    return res.code != "404" # false if returns 404 - not found
  end

  def get_individual_gun_show_data(gun_show_title)
    require 'net/http'
    require 'open-uri'
    url_string = "https://gunshowtrader.com/gun-shows/#{gun_show_title}/"
    uri = URI.parse(url_string)
    if (Net::HTTP.get_response(uri).code != '200')
      return nil
    elsif (Net::HTTP.get_response(uri).code == '200')
      doc = Nokogiri::HTML(open(url_string).read)
      if (url_exists(url_string))
        state = get_state(doc)
        
        obj = {
          title: get_title(doc),
          dates: get_dates(doc),
          rating: get_rating(doc),
          city: get_city(doc),
          state: state,
          state_full: get_state_full(state),
          hours: get_hours(doc),
          description: get_description(doc),
          promoter: get_promoter(doc, gun_show_title),
          location: get_location(doc),
          vendor_info: get_vendor_info(doc),
          admission: get_admission(doc)
        }
        
        return parse_location(obj)
      end
    end
  end

  def create_record(item)
    Event.create(item)
  end

  def returnMatchingPairsinDB()
    array = []
    getUniqueEvents().each do |event_object|
      event = Event.where(title: event_object[:title], location: event_object[:location])
      array << event.order('created_at DESC').limit(2)
    end
    return array
  end

  def getUniqueEvents
    array = []
    Event.select(:title, :location)
      .map do |item| 
        if (!findEvent(item, array))
          array << { title: item[:title], location: item[:location] }
        end
      end
    return array
  end

  def findEvent(item, array)
    array.find do |a| 
      a[:title] == item[:title] && a[:location] == item[:location] 
    end
  end

  def get_US_states()
    states = []
    STATES.each do |line|
      states << line.strip()
    end
    return states
  end

  def get_title(doc)
    puts 'get title'
    return doc.css('h1.entry-title').text
  end

  def get_dates(doc)
    puts 'get dates'
    if (!doc.css('div.three-fourths.text.dates').empty?)
      run_date_selector(doc, 'dates')
    else
      run_date_selector(doc, 'date')
    end
  end

  def run_date_selector(doc, input)
    dates = []
    selector = "div.three-fourths.text." + input
    doc.css(selector).css('ul').css('li').each do |item|
      dates << item.css('.date-display').text
    end
    return dates
  end

  def get_rating(doc)
    puts 'get rating'
    if (!doc.css('.three-fourths.text.rating').empty?)
      return doc.css('.three-fourths.text.rating').css('.review-link').attr('title').value.split()[1]
    else
      return ''
    end
  end

  def get_city(doc)
    puts 'get city'
    return doc.css('.three-fourths.text.city\/state').text.split(',')[0]
  end

  def get_state(doc)
    return doc.css('.three-fourths.text.city\/state').text.split(', ')[1]
  end

  def get_state_full(state_abbr)
    index = STATES_ABBR.find_index(state_abbr)
    return STATES[index]
  end

  def get_hours(doc)
    puts 'get hours'
    result = []
    doc.css('div.three-fourths.text.hours').css('li').each do |item|
      day_of_week = item.text.split(': ')[0]
      hours = item.text.split(': ')[1]
      result << { day_of_week: day_of_week, hours: hours }
    end
    return result
  end

  def get_admission(doc)
    puts 'get admission'
    if (doc.css('.event-price').text().length > 0)
      return doc.css('.event-price').text()
    elsif (doc.css('.event-info li p').text().length > 0)
      return doc.css('.event-info li p').text()
    end
  end

  def get_description(doc)
    puts 'get descr'
    if (doc.at('div.one-fourth.first.label:contains("Description")'))
      return doc.at('div.one-fourth.first.label:contains("Description")').next_element.text
    end
  end

  def get_promoter(doc, gun_show_title)
    puts 'get promoter'
    org = doc.css('div.organization')
    obj = {}
    
    
    
    obj['organization_name'] = org.css('span.organization-name').text
    puts '1'
    
    # if (gun_show_title == 'slidell-gun-knife-show')
    #   binding.pry
    # end
    if (!org.css('ul.organization-contact').css('div').css('li').empty? && !doc.css('.organization-contact li')[2].nil?)
      if (doc.css('.organization-contact li').text.include?('Email:'))
        obj['organization_contact_email'] = doc.css('.organization-contact li')[1].text.split('Email: ')[1]
      end
      puts '2a'
    elsif (!org.css('ul.organization-contact').css('ul li').empty?)
      puts 'd', obj['organization_contact_email'] = org.css('ul.organization-contact').css('ul li')[0].text.split(':')[1].strip
      obj['organization_contact_email'] = org.css('ul.organization-contact').css('ul li')[0].text.split(':')[1].strip
    end
    if (org.css('ul.organization-contact').css('ul li').length > 1)
      obj['organization_contact_email'] = org.css('ul.organization-contact').css('ul li')[1].text.split('Email: ')[1]
    end
    puts '2'
    if (!org.css('ul.organization-contact').css('div').css('li').empty?)
      if (org.css('ul.organization-contact').text.include?('Phone:'))
        obj['organization_contact_phone'] = org.css('ul.organization-contact').text.split('Phone:')[1].strip
      end
    end
    puts 3
    if (!org.css('ul.organization-contact').css('div').css('li').empty?)
      obj['organization_contact_name'] = org.css('ul.organization-contact').css('div').css('li')[0].text.split(': ')[1]
    end
    puts '4'
    if (!org.css('ul.organization-contact').css('div').css('li').empty?)
      obj['organization_contact_phone'] = org.css('ul.organization-contact').css('div').css('li')[1].text.split(': ')[1]
    end
    puts '5'
    return obj
  end

  def get_location(doc)
    puts 'get location'
    location = ""
    data = doc.css('div.location div').text.split("\n")
    data.each do |item|
      if !item.empty?
        location += ' ' + item
      end
    end
    return location.strip()
  end

  def parse_location(obj)
    puts 'parse location 0'
    puts obj
    require 'Indirizzo'
    a = Indirizzo::Address.new(obj[:location])
    puts a
    
    puts 'parse_location 1'
    addr_number = /\d+/.match(a.text).to_s()
    addr = nil
    
    puts 'parse_location 2'
    if (addr_number != a.zip) 
      obj[:location_name] = a.text.split(addr_number)[0].strip()
      addr = a.text.split(addr_number)[1].strip()
    elsif (addr_number == a.zip)
      addr = a.text
    end
    
    puts 'parse_location 3'
    
    addr.split(' ').each_with_index do |s, i|
      if (s.include?(','))
        if (addr_number != a.zip)
          obj[:location_street] = /\d+/.match(a.text).to_s() + ' ' + addr.split(s)[0].strip()
        elsif (addr_number == a.zip)
          obj[:location_street] = addr.split(s)[0].strip()
          obj[:location_name] = addr.split(s)[0].strip()
        end
      end
    end

    puts 'parse_location 4'
    
    obj[:location_city] = a.city[0].split.map(&:capitalize).join(' ')
    obj[:location_state] = a.state
    obj[:location_zip] = a.zip
    puts 'parse_location 5'
    
    return obj
  end

  def get_vendor_info(doc)
    puts 'get vendor_info'
    array = []
    doc.css('div.three-fourths.text.vendor p').each do |item|
      array << item.text
    end
    return array
  end
end
