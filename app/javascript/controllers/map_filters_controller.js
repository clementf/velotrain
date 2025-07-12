import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggleTracks(event) {
    const button = event.target;

    if (button.ariaChecked === "false") {
      button.ariaChecked = "true";
      button.querySelector("span.slider-bg").classList.remove("bg-gray-200");
      button.querySelector("span.slider-bg").classList.add("bg-accent-dark");

      button.querySelector("span.slider-fg").classList.remove("translate-x-0");
      button.querySelector("span.slider-fg").classList.add("translate-x-5");
      document.dispatchEvent(new CustomEvent("enabled-filter:tracks"));

    } else {
      button.ariaChecked = "false";
      button.querySelector("span.slider-bg").classList.remove("bg-accent-dark");
      button.querySelector("span.slider-bg").classList.add("bg-gray-200");

      button.querySelector("span.slider-fg").classList.remove("translate-x-5");
      button.querySelector("span.slider-fg").classList.add("translate-x-0");
      document.dispatchEvent(new CustomEvent("disabled-filter:tracks"));
    }
  }

  toggleAccommodations(event) {
    const button = event.target;

    if (button.ariaChecked === "false") {
      button.ariaChecked = "true";
      button.querySelector("span.slider-bg").classList.remove("bg-gray-200");
      button.querySelector("span.slider-bg").classList.add("bg-accent-dark");

      button.querySelector("span.slider-fg").classList.remove("translate-x-0");
      button.querySelector("span.slider-fg").classList.add("translate-x-5");
      document.dispatchEvent(new CustomEvent("enabled-filter:accommodations"));

    } else {
      button.ariaChecked = "false";
      button.querySelector("span.slider-bg").classList.remove("bg-accent-dark");
      button.querySelector("span.slider-bg").classList.add("bg-gray-200");

      button.querySelector("span.slider-fg").classList.remove("translate-x-5");
      button.querySelector("span.slider-fg").classList.add("translate-x-0");
      document.dispatchEvent(new CustomEvent("disabled-filter:accommodations"));
    }
  }
}
