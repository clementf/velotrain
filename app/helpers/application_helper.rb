module ApplicationHelper
  include Pagy::Frontend
  
  def pagy_tailwind_nav(pagy)
    return "" unless pagy.pages > 1
    
    links = []
    
    # Previous button
    if pagy.prev
      links << link_to("Previous", pagy_url_for(pagy, pagy.prev), 
        class: "relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0")
    else
      links << content_tag(:span, "Previous", 
        class: "relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed")
    end
    
    # Page numbers
    pagy.series.each do |item|
      case item
      when Integer
        if item == pagy.page
          links << content_tag(:span, item, 
            class: "relative z-10 inline-flex items-center bg-emerald-600 px-4 py-2 text-sm font-semibold text-white focus:z-20 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-emerald-600")
        else
          links << link_to(item, pagy_url_for(pagy, item), 
            class: "relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-900 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0")
        end
      when String
        links << content_tag(:span, item, 
          class: "relative inline-flex items-center px-4 py-2 text-sm font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0")
      end
    end
    
    # Next button
    if pagy.next
      links << link_to("Next", pagy_url_for(pagy, pagy.next), 
        class: "relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 hover:bg-gray-50 focus:z-20 focus:outline-offset-0")
    else
      links << content_tag(:span, "Next", 
        class: "relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-300 ring-1 ring-inset ring-gray-300 cursor-not-allowed")
    end
    
    content_tag(:nav, class: "flex items-center justify-between") do
      content_tag(:div, class: "flex flex-1 justify-center") do
        content_tag(:div, class: "isolate inline-flex -space-x-px rounded-md shadow-sm") do
          safe_join(links)
        end
      end
    end
  end
  
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
