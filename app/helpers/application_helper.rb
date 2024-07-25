module ApplicationHelper
  def display_time(time)
    time.in_time_zone("Europe/Paris").strftime("%H:%M")
  end

  def display_duration(seconds)
    return "0h0" if seconds <= 0

    total_minutes = (seconds / 60).to_i
    hours = total_minutes / 60
    minutes = total_minutes % 60

    "#{hours}h#{minutes.to_s.rjust(2, '0')}"
  end
end
