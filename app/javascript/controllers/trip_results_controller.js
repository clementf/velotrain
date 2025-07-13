import { Controller } from "@hotwired/stimulus";
import maplibregl from "maplibre-gl";

export default class extends Controller {
  connect() {
    // Only initialize if there are trip elements on the page
    if (document.querySelectorAll('.trip').length === 0) {
      return;
    }

    if (window.section_layers === undefined) {
      window.section_layers = [];
    }

    this.mapReadyHandler = this.handleMapReady.bind(this);
    
    // Listen for map ready event
    document.addEventListener("map:ready", this.mapReadyHandler);
    
    // Check if map is already ready
    if (window.map && window.map.loaded()) {
      this.setupObserver();
    }
  }

  handleMapReady(event) {
    this.setupObserver();
  }

  disconnect() {
    // Remove event listener
    document.removeEventListener("map:ready", this.mapReadyHandler);
    this.removeLayers();
  }

  setupObserver() {
    // Ensure map is available
    if (!window.map) {
      return;
    }

    let targets = document.querySelectorAll('.trip');
    
    // Show first section if it exists
    if (targets[0]) {
      this.showSection(targets[0]);
    }

    targets.forEach(target => {
      target.addEventListener('mouseenter', (event) => {
        this.showSection(target);
      })
    });
  }

  showSection(target) {
    // Defensive programming - ensure target exists and has the required method
    if (!target || typeof target.querySelectorAll !== 'function') {
      return;
    }

    // Ensure map is available
    if (!window.map) {
      return;
    }

    let idx = 0;

    this.removeLayers();
    window.section_layers = [];

    let bounds = new maplibregl.LngLatBounds();
    let sections = target.querySelectorAll('.section');
    
    // Check if any sections exist
    if (sections.length === 0) {
      return;
    }

    sections.forEach((section) => {
      try {
        if (section.dataset.geoJson) {
          const geoData = JSON.parse(section.dataset.geoJson);
          if (geoData.coordinates) {
            geoData.coordinates.forEach((coord) => {
              bounds.extend(coord);
            });
          }
        }
      } catch (error) {
        // Silently fail on parsing errors
      }
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
