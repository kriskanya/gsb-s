class EventsController < ApplicationController
  helper_method :checkEventEquality

  def index
    event = Event.new()
    @US_states = event.get_US_states()
    @events = event.returnMatchingPairsinDB()
  end

  def scrape
    if (params[:states])
      Thread.new do
        event = Event.new()
        gun_shows_array = event.start(params[:states])
        redirect_to root_path
      end
    end
  end

  def clear_database
    Event.delete_all()
    redirect_to root_path
  end

  def checkEventEquality(index, parameter)
    param = parameter.to_sym
    if (@events[index].count > 1 && (@events[index][0][param] != @events[index][1][param]))
      return 'red'
    end
  end
end
