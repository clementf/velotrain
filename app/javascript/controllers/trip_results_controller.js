import { Controller } from "@hotwired/stimulus";
import maplibregl from "maplibre-gl";

export default class extends Controller {
  connect() {
    if (window.trip_layers === undefined) {
      window.trip_layers = [];
    }

    let ids = this.element.dataset.stopIds;

    fetch(`/api/trips/id?stop_ids=${ids}`)
      .then((response) => response.json())
      .then((data) => {
        let idx = 0;
        window.trip_layers.forEach((layer) => {
          window.map.removeLayer(layer);
          window.map.removeSource(layer);
        });
        window.trip_layers = [];
        data.path.forEach((trip) => {
          idx += 1;
          window.trip_layers.push("trip_" + idx);
          window.map.addSource("trip_" + idx, {
            type: "geojson",
            data: trip,
          });
          window.map.addLayer({
            id: "trip_" + idx,
            type: "line",
            source: "trip_" + idx,
            layout: {
              "line-join": "round",
              "line-cap": "round",
            },
            paint: {
              "line-color": "#065f46",
              "line-opacity": 0.8,
              "line-width": 5,
            },
          });
        });

        // Fit map to trip
        let bounds = data.bounds;
        window.map.fitBounds(bounds, {
          padding: { top: 50, bottom: 50, left: 450, right: 200 },
          duration: 400,
        });
      });
  }
}
