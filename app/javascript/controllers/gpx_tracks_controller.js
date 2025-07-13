import maplibregl from "maplibre-gl";
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = []

  connect() {
    this.map = null;
    this.selectedTrackId = null;
    this.popup = null;
    this.accentColor = '#E66A5F';
    this.mapReadyHandler = this.handleMapReady.bind(this);
    this.pathsLoadedHandler = this.setupTrackInteractions.bind(this);

    // Listen for map ready event
    document.addEventListener("map:ready", this.mapReadyHandler);

    // Listen for paths loaded event
    document.addEventListener("gpx-tracks:paths-loaded", this.pathsLoadedHandler);

    // Try to setup immediately if map is already available
    if (window.map && window.map.loaded()) {
      this.map = window.map;
      this.setupTrackInteractions();
    }
  }

  handleMapReady(event) {
    this.map = event.detail.map;
    // Don't call setupTrackInteractions here - wait for paths to be loaded
  }

  setupTrackInteractions() {
    // Get map from event or window if not already set
    if (!this.map && window.map) {
      this.map = window.map;
    }

    // Only proceed if map is available and loaded
    if (!this.map || !this.map.loaded()) {
      setTimeout(() => this.setupTrackInteractions(), 100);
      return;
    }


    try {
      // Wait for the paths layer to be added to the map
      this.map.on('sourcedata', (e) => {
        if (e.sourceId === 'paths' && e.isSourceLoaded) {
          this.addTrackClickHandler();
        }
      });

      // Also setup handler if paths layer already exists
      if (this.map.getSource('paths')) {
        this.addTrackClickHandler();
      }
    } catch (error) {
    }
  }

  addTrackClickHandler() {

    // Ensure map and layers exist
    if (!this.map || !this.map.loaded()) {
      return;
    }

    // Check if the clickable layer exists
    if (!this.map.getLayer('paths-clickable')) {
      if (!this.map.getLayer('paths')) {
        return;
      }
      // Use paths layer instead of paths-clickable if clickable doesn't exist
      this.setupHandlersForLayer('paths');
      return;
    }

    this.setupHandlersForLayer('paths-clickable');
  }

  setupHandlersForLayer(layerName) {
    try {
      // Remove existing handlers to avoid duplicates
      this.map.off('click', layerName, this.handleTrackClick);
      this.map.off('mouseenter', layerName, this.handleTrackMouseEnter);
      this.map.off('mouseleave', layerName, this.handleTrackMouseLeave);

      // Add click handler for GPX tracks
      this.map.on('click', layerName, this.handleTrackClick.bind(this));

      // Add hover effects
      this.map.on('mouseenter', layerName, this.handleTrackMouseEnter.bind(this));
      this.map.on('mouseleave', layerName, this.handleTrackMouseLeave.bind(this));

      // Add click handler for map (to close popup when clicking away)
      this.map.on('click', this.handleMapClick.bind(this));

    } catch (error) {
    }
  }

  handleTrackClick = (e) => {
    e.preventDefault();
    const feature = e.features[0];

    if (!feature) {
      return;
    }

    const properties = feature.properties;

    // Close existing popup
    if (this.popup) {
      this.popup.remove();
    }

    // Highlight only this track
    this.highlightTrack(properties.track_id);

    // Create popup
    this.showTrackPopup(e.lngLat, properties);
  }

  handleTrackMouseEnter = () => {
    this.map.getCanvas().style.cursor = 'pointer';
  }

  handleTrackMouseLeave = () => {
    this.map.getCanvas().style.cursor = '';
  }

  handleMapClick = (e) => {
    // Check if click was on a track (using the clickable layer)
    const features = this.map.queryRenderedFeatures(e.point, {
      layers: ['paths-clickable']
    });

    // If click was not on a track, restore all tracks and close popup
    if (features.length === 0) {
      this.restoreAllTracks();
      if (this.popup) {
        this.popup.remove();
        this.popup = null;
      }
    }
  }

  highlightTrack(trackId) {
    this.selectedTrackId = trackId;

    // Update the paint properties to highlight the selected track
    this.map.setPaintProperty('paths', 'line-color', [
      'case',
      ['==', ['get', 'track_id'], trackId],
      this.accentColor, // Accent color for selected track
      '#94a3b8'  // Muted gray for other tracks
    ]);

    this.map.setPaintProperty('paths', 'line-width', [
      'case',
      ['==', ['get', 'track_id'], trackId],
      4, // Thicker line for selected track
      1  // Thinner line for other tracks
    ]);

    this.map.setPaintProperty('paths', 'line-opacity', [
      'case',
      ['==', ['get', 'track_id'], trackId],
      1.0, // Full opacity for selected track
      0.3  // Reduced opacity for other tracks
    ]);
  }

  restoreAllTracks() {
    this.selectedTrackId = null;

    // Restore original paint properties
    this.map.setPaintProperty('paths', 'line-color', '#274c77');
    this.map.setPaintProperty('paths', 'line-width', 2);
    this.map.setPaintProperty('paths', 'line-opacity', 0.9);
  }

  showTrackPopup(lngLat, properties) {
    // Count segments for this track
    const trackFeatures = this.map.querySourceFeatures('paths', {
      filter: ['==', ['get', 'track_id'], properties.track_id]
    });
    const segmentsCount = trackFeatures.length;

    this.popup = new maplibregl.Popup({
      className: 'gpx-track-popup',
      closeButton: false,
      maxWidth: '280px'
    })
      .setLngLat(lngLat)
      .setHTML(`
        <div class="rounded-lg bg-white shadow-lg font-sans overflow-hidden border border-gray-200">
          <div class="px-4 py-3">
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <h3 class="text-sm font-semibold text-gray-900 leading-tight mb-2">
                  ${properties.name}
                </h3>
                <div class="flex items-center space-x-4 text-xs text-gray-600">
                  <div class="flex items-center">
                    <svg class="w-3 h-3 mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6"></path>
                    </svg>
                    <span class="font-medium">${properties.distance_km} km</span>
                  </div>
                </div>
              </div>
              <button class="ml-2 text-gray-400 hover:text-gray-600 transition-colors" onclick="this.closest('.maplibregl-popup').remove()">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path>
                </svg>
              </button>
            </div>
          </div>
        </div>
      `)
      .addTo(this.map);

    // Store reference to controller for cleanup
    this.popup._gpxController = this;

    // Handle popup close
    this.popup.on('close', () => {
      this.restoreAllTracks();
      this.popup = null;
    });
  }

  disconnect() {
    if (this.popup) {
      this.popup.remove();
    }

    // Remove event listeners
    document.removeEventListener("map:ready", this.mapReadyHandler);
    document.removeEventListener("gpx-tracks:paths-loaded", this.pathsLoadedHandler);

    if (this.map) {
      this.map.off('click', 'paths-clickable', this.handleTrackClick);
      this.map.off('mouseenter', 'paths-clickable', this.handleTrackMouseEnter);
      this.map.off('mouseleave', 'paths-clickable', this.handleTrackMouseLeave);
      this.map.off('click', this.handleMapClick);
    }
  }
}
