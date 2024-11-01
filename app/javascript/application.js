// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "ahoy"
import "chartkick"
import "Chart.bundle"

ahoy.configure({cookies: false, trackVisits: true})

document.addEventListener("turbo:load", function() {
  ahoy.trackView();
})
