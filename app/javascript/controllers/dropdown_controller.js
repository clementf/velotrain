import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  toggle(event) {
    const dropdown = this.element.querySelector("div[role='menu']");
    dropdown.classList.toggle("hidden");
    event.preventDefault();
  }

  hide(event) {
    if (this.element.querySelector("button").contains(event.target)) {
      return
    }

    const dropdown = this.element.querySelector("div[role='menu']");
    dropdown.classList.add("hidden");
  }
}
