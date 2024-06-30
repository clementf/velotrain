module ApplicationHelper
  def display_time(time)
    time.in_time_zone("Europe/Paris").strftime("%H:%M")
  end
end
