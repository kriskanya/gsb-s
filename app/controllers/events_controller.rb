class EventsController < ApplicationController
  helper_method :checkEventEquality

  def index
    event = Event.new()
    @US_states = event.get_US_states()
    @events = event.returnMatchingPairsinDB()
  end

  def scrape
    Thread.new do
      event = Event.new()
      gun_shows_array = event.start(params[:states])
      redirect_to root_path
    end
  end

  def clear_database
    Event.delete_all()
    redirect_to root_path
  end

  def export_csv
    @events = Event.all.order('created_at DESC').limit(2000)
    respond_to do |format|
      format.html
      format.csv { send_data @events.to_csv, filename: "events-#{Date.today}.csv" }
    end
  end

  def export_csv2
    @events = Event.all.order('created_at DESC').limit(2000)
    respond_to do |format|
      format.html
      format.csv { send_data @events.to_csv_location_only, filename: "event-locations-#{Date.today}.csv" }
    end
  end

  def checkEventEquality(index, parameter)
    param = parameter.to_sym
    if (@events[index].count > 1 && (@events[index][0][param] != @events[index][1][param]))
      return 'red'
    end
  end
end
