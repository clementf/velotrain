import { Controller } from "@hotwired/stimulus";
import maplibregl from "maplibre-gl";

export default class extends Controller {
  connect() {
    if (window.section_layers === undefined) {
      window.section_layers = [];
    }

    if(window.map.loaded()) {
      this.setupObserver();
    }
    else {
      // Wait for the map to load. Can't use load event b/c it's only fired once
      // Similar to issue described here: https://github.com/mapbox/mapbox-gl-js/issues/6707
      window.setTimeout(() => {
        if(window.map.loaded()) {
          this.setupObserver();
        }
      }, 200);
    }

    // Still need to check if the map is loaded when the load event is fired
    window.map.on('load', () => {
      this.setupObserver();
    });
  }

  disconnect() {
    this.removeLayers();
  }

  setupObserver() {
    let targets = document.querySelectorAll('.trip');

    this.showSection(targets[0]);

    targets.forEach(target => {
      target.addEventListener('mouseenter', (event) => {
        this.showSection(target);
      })
    });
  }

  showSection(target) {
    let idx = 0;

    this.removeLayers();
    window.section_layers = [];

    let bounds = new maplibregl.LngLatBounds();

    target.querySelectorAll('.section').forEach((section) => {
      JSON.parse(section.dataset.geoJson).coordinates.forEach((coord) => {
        bounds.extend(coord);
      });
    });

    let paddingLeft = document.body.clientWidth > 768 ? document.querySelector('#search-container').offsetWidth + 50 : 50;
    let paddingBottom = document.body.clientWidth < 768 ? 350 : 50;

    window.map.fitBounds(bounds, {
      duration: 200,
      padding: { top: 50, bottom: paddingBottom, left: paddingLeft, right: 50 }
    });

    target.querySelectorAll('.section').forEach((section) => {
      idx += 1;
      window.section_layers.push("section_" + idx);

      window.map.addSource("section_" + idx, {
        type: "geojson",
        data: JSON.parse(section.dataset.geoJson),
      });

      window.map.addLayer({
        id: "section_" + idx,
        type: "line",
        source: "section_" + idx,
        layout: {
          "line-join": "round",
          "line-cap": "round",
        },
        paint: {
          "line-color": "#444",
          "line-opacity": 0.8,
          "line-width": 2.5,
        },
      });
    });
  }

  removeLayers() {
    window.section_layers.forEach((layer) => {
      if(window.map.getLayer(layer)) {
        window.map.removeLayer(layer);
      }
      if(window.map.getSource(layer)) {
        window.map.removeSource(layer);
      }
    });
  }
}
