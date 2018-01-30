class EventsController < ApplicationController
  helper_method :checkEventEquality

  def index
    event = Event.new()
    @US_states = event.get_US_states()
    @events = event.returnMatchingPairsinDB()
  end

  def scrape
    event = Event.new()
    if (params[:states])
      event.start(params[:states])
    end
    redirect_to events_path
  end

  def clear_database
    Event.delete_all()
    redirect_to events_path
  end

  def checkEventEquality(index, parameter)
    param = parameter.to_sym
    if (@events[index].count > 1 && (@events[index][0][param] != @events[index][1][param]))
      return 'red'
    end
  end
end
