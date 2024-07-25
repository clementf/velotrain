import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  swap() {
    const from = this.element.querySelector("#from_stop_id");
    const to = this.element.querySelector("#to_stop_id");
    const fromHidden = this.element.querySelector("#from_stop_id-hw-hidden-field");
    const toHidden = this.element.querySelector("#to_stop_id-hw-hidden-field");

    const fromText = from.value;
    const toText = to.value;
    const fromValue = fromHidden.value;
    const toValue = toHidden.value;

    from.value = toText;
    to.value = fromText;
    fromHidden.value = toValue;
    toHidden.value = fromValue;
  }
}
