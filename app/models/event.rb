class Event < ApplicationRecord
  STATES = ['Alabama','Alaska','Arizona','Arkansas','California','Colorado','Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho','Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine','Maryland','Massachusetts','Michigan','Minnesota','Mississippi','Missouri','Montana','Nebraska','Nevada','New Hampshire','New Jersey','New Mexico','New York','North Carolina','North Dakota','Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island','South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont','Virginia','Washington','West Virginia','Wisconsin','Wyoming']
  def start(states_selected = nil)
    if (states_selected)
      scrape(states_selected)
    end
  end

  def scrape(states_selected)
    @gun_show_data = []
    get_all_gunshow_titles(states_selected).each do |gun_show_title|
      @gun_show_data << get_individual_gun_show_data(gun_show_title)
      sleep 1
    end 
    puts @gun_show_data
  end

  def get_all_gunshow_titles(states_selected)
    require 'open-uri'
    gun_show_titles = []
    states_selected.each do |us_state|
      doc = Nokogiri::HTML(open("https://gunshowtrader.com/gunshows/#{us_state}/").read)
      doc.css('a.event-link').each do |item|
        gun_show_titles << item.attr('href').split('gun-shows/')[1].gsub('/', '')
      end
    end
    # gun_show_titles = ['fort-oglethorpe-gun-show']
    return gun_show_titles
  end

  def get_individual_gun_show_data(gun_show_title)
    require 'open-uri'
    doc = Nokogiri::HTML(open("https://gunshowtrader.com/gun-shows/#{gun_show_title}/").read)
    obj = {
      title: get_title(doc),
      dates: get_dates(doc),
      rating: get_rating(doc),
      city: get_city(doc),
      state: get_state(doc),
      hours: get_hours(doc),
      description: get_description(doc),
      promoter: get_promoter(doc),
      location: get_location(doc),
      vendor_info: get_vendor_info(doc)
    }
    create_record(obj)
  end

  def create_record(obj)
    Event.create(obj)
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
    binding.pry
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

  def get_hours(doc)
    result = []
    doc.css('div.three-fourths.text.hours').css('li').each do |item|
      day_of_week = item.text.split(': ')[0]
      hours = item.text.split(': ')[1]
      result << { dayOfWeek: day_of_week, hours: hours }
    end
    return result
  end

  def get_description(doc)
    return doc.at('div.one-fourth.first.label:contains("Description")').next_element.text
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
