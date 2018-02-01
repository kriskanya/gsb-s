class Event < ApplicationRecord
  STATES = ['Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming']
  STATES_ABBR = ['AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA', 'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD', 'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ', 'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC', 'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY']
  def start(states_selected = nil)
    if (states_selected)
      scrape(states_selected)
    end
  end

  def scrape(states_selected)
    gun_show_data = []
    get_all_gunshow_titles(states_selected).each do |gun_show_title|
      new_record = get_individual_gun_show_data(gun_show_title)
      if (gun_show_data.select { |d| d[:title] == new_record[:title] && d[:location] == new_record[:location] }.length == 0)
        gun_show_data << new_record
        create_record(new_record)
      end
      sleep 1
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
          gun_show_titles << item.attr('href').split('gun-shows/')[1].gsub('/', '')
        end
      end
    end
    # gun_show_titles = ['fort-oglethorpe-gun-show']
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
    require 'open-uri'
      url_string = "https://gunshowtrader.com/gun-shows/#{gun_show_title}/"
      if (url_exists(url_string))
        doc = Nokogiri::HTML(open(url_string).read)
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
          promoter: get_promoter(doc),
          location: get_location(doc),
          vendor_info: get_vendor_info(doc)
        }
      end
  end

  def create_record(item)
    Event.create(item)
  end

  def returnMatchingPairsinDB()
    # event = Event.where(title: event_obj[:title], location: event_obj[:location])
    array = []
    getUniqueEventNames().each do |event_title|
      event = Event.where(title: event_title)
      array << event.order('created_at DESC').limit(2)
    end
    return array
  end

  def getUniqueEventNames
    return Event.select(:title).map(&:title).uniq
  end

  def get_US_states()
    states = []
    STATES.each do |line|
      states << line.strip()
    end
    return states
  end

  def get_title(doc)
    return doc.css('h1.entry-title').text
  end

  def get_dates(doc)
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
    if (!doc.css('.three-fourths.text.rating').empty?)
      return doc.css('.three-fourths.text.rating').css('.review-link').attr('title').value.split()[1]
    else
      return ''
    end
  end

  def get_city(doc)
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
    result = []
    doc.css('div.three-fourths.text.hours').css('li').each do |item|
      day_of_week = item.text.split(': ')[0]
      hours = item.text.split(': ')[1]
      result << { day_of_week: day_of_week, hours: hours }
    end
    return result
  end

  def get_description(doc)
    if (doc.at('div.one-fourth.first.label:contains("Description")'))
      return doc.at('div.one-fourth.first.label:contains("Description")').next_element.text
    end
  end

  def get_promoter(doc)
    org = doc.css('div.organization')
    obj = {}
    obj['organization_name'] = org.css('span.organization-name').text
    if (!org.css('ul.organization-contact').css('div').css('li').empty?)
      obj['organization_contact_name'] = org.css('ul.organization-contact').css('div').css('li')[0].text.split(': ')[1]
    end
    if (!org.css('ul.organization-contact').css('div').css('li').empty?)
      obj['organization_contact_phone'] = org.css('ul.organization-contact').css('div').css('li')[1].text.split(': ')[1]
    end
    return obj
  end

  def get_location(doc)
    location = ""
    data = doc.css('div.location div').text.split("\n")
    data.each do |item|
      if !item.empty?
        location += ' ' + item
      end
    end
    return location.strip()
  end

  # def get_table_count(doc)
  #   return doc.css('div.three-fourths.text.vendor').text.split("\n")[0].split(' ')[0]
  # end

  # def get_price_per_table(doc)
  #   return doc.css('div.three-fourths.text.vendor').text.split("\n")[1].split(' ')[1]
  # end

  def get_vendor_info(doc)
    array = []
    doc.css('div.three-fourths.text.vendor p').each do |item|
      array << item.text
    end
    return array
  end
end
