import maplibregl from "maplibre-gl";
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    var map = new maplibregl.Map({
      container: "map", // container id
      style:
        "https://api.protomaps.com/styles/v2/light.json?key=425d73f4d592980c", // style URL
      bounds: [
        [16, 51.5],
        [-9, 42.37],
      ],
    });

    window.map = map;
    let zoomLevel = 0;
    let simplifiedZoom = 0;

    let firstSymbolId;

    const fetchIsochrone = async (range) => {
      const zoom = Math.round(map.getZoom());
      if (zoom < 9) {
        simplifiedZoom = 5;
      }
      if (zoom > 9) {
        simplifiedZoom = 10;
      }

      const response = await fetch(
        `api/isochrones?range=${range}&zoom=${simplifiedZoom}`,
      );
      return await response.json();
    };

    const addIsochrone = async (range, fillColor) => {
      const data = await fetchIsochrone(range);

      map.addSource(`isochrones-${range}`, {
        type: "geojson",
        data: data, // GeoJSON data retrieved from your API endpoint
      });

      map.addLayer(
        {
          id: `isochrones-${range}`,
          type: "fill", // Adjust the type according to your data
          source: `isochrones-${range}`,
          paint: {
            "fill-color": fillColor || "#088",
            "fill-opacity": 0.5,
            "fill-opacity-transition": { duration: 150 },
            "fill-antialias": true,
            "fill-outline-color": "#088",
          },
        },
        firstSymbolId,
      );
    };

    const addTrainLines = async () => {
      const response = await fetch("api/train_lines");
      const data = await response.json();

      map.addSource("train_lines", {
        type: "geojson",
        data: data,
      });

      map.addLayer(
        {
          id: "train_lines",
          type: "line",
          source: "train_lines",
          paint: {
            "line-color": "#666",
            "line-width": 1,
            "line-opacity": 0.6,
          },
        },
        firstSymbolId,
      );
    };

    const addStationLabelLayer = (map, category, minZoom) => {
      map.addLayer({
        id: `train_station_labels_${category}`,
        type: "symbol",
        source: "train_stations",
        layout: {
          "text-field": ["get", "name"],
          "text-font": ["Noto Sans Medium"],
          "text-size": 12,
          "text-anchor": "bottom",
        },
        minzoom: minZoom,
        filter: ["==", ["get", "drg"], category],
        paint: {
          "text-color": "#333",
          "text-halo-color": "rgba(255,255,255,0.5)",
          "text-halo-width": 1,
        },
      });
    };

    const addTrainStations = async () => {
      const response = await fetch("api/train_stations");
      const data = await response.json();

      map.addSource("train_stations", {
        type: "geojson",
        data: data,
      });

      map.addLayer({
        id: "train_stations",
        type: "circle",
        source: "train_stations",
        minzoom: 8,
        paint: {
          "circle-color": "#555",
          "circle-radius": 2,
          "circle-opacity": 0.8,
        },
      });

      addStationLabelLayer(map, "A", 7);
      addStationLabelLayer(map, "B", 8);
      addStationLabelLayer(map, "C", 9);

      ['A', 'B', 'C'].forEach(category => {
        map.on("click", `train_station_labels_${category}`, function (e) {
          displayStationRelatedIsochrones(e);
        });

        map.on("mouseenter", `train_station_labels_${category}`, function () {
          map.getCanvas().style.cursor = "pointer";
        });

        map.on("mouseleave", `train_station_labels_${category}`, function () {
          map.getCanvas().style.cursor = "";
        });
      });
    };

    const displayStationRelatedIsochrones = async (e) => {
      const stationCode = e.features[0].properties.code;


      const response = await fetch(`api/train_stations/isochrones?code=${stationCode}`);
      const data = await response.json();

      const rangeColors = [
        [3600, '#ffd97d'],
        [1800, '#aaf683'],
        [900, '#60d394']
      ];

      // Fade out existing isochrone layers
      [3600, 1800, 900].forEach(range => {
        map.setPaintProperty(`isochrones-${range}`, 'fill-opacity', 0);
      });

      rangeColors.forEach(([range, color]) => {
        const sourceId = `station-isochrone-${range}`;
        const layerId = `station-isochrone-${range}`;

        const rangeData = {
          type: 'FeatureCollection',
          features: data.features.filter(f => f.properties.range === parseInt(range))
        };

        if (map.getSource(sourceId)) {
          map.getSource(sourceId).setData(rangeData);
        } else {
          map.addSource(sourceId, {
            type: 'geojson',
            data: rangeData
          });

          map.addLayer({
            id: layerId,
            type: 'fill',
            source: sourceId,
            paint: {
              'fill-color': color,
              'fill-opacity': 0, // Start with 0 opacity
              'fill-opacity-transition': { duration: 150 }, // Add transition
              'fill-antialias': true,
              "fill-outline-color": "#088",
            }
          }, firstSymbolId);
        }

        // Fade in the layer
        map.setPaintProperty(layerId, 'fill-opacity', 0.5);
      });
    };

    const showAllIsochrones = () => {
      // Fade out station-specific isochrone layers
      [3600, 1800, 900].forEach(range => {
        const layerId = `station-isochrone-${range}`;
        if (map.getLayer(layerId)) {
          map.setPaintProperty(layerId, 'fill-opacity', 0);
        }
      });

      // Fade in general isochrone layers
      [3600, 1800, 900].forEach(range => {
        const layerId = `isochrones-${range}`;
        if (!map.getPaintProperty(layerId, 'fill-opacity-transition')) {
          map.setPaintProperty(layerId, 'fill-opacity-transition', {
            duration: 150
          });
        }
        map.setPaintProperty(layerId, 'fill-opacity', 0.5);
      });
    };

    map.on("load", async () => {
      zoomLevel = map.getZoom();
      const layers = map.getStyle().layers;
      for (let i = 0; i < layers.length; i++) {
        if (layers[i].type === "symbol") {
          firstSymbolId = layers[i].id;
          break;
        }
      }

      addAttribution();

      await addIsochrone(3600, "#ffd97d");
      await addIsochrone(1800, "#aaf683");
      await addIsochrone(900, "#60d394");

      addTrainLines();
      addTrainStations();

      // Add click handler for the map
      map.on('click', (e) => {
        // Check if the click was on a station label (if so, the station handler will take care of it)
        const features = map.queryRenderedFeatures(e.point, {
          layers: ['train_station_labels_A', 'train_station_labels_B', 'train_station_labels_C']
        });

        if (features.length === 0) {
          showAllIsochrones();
        }
      });

      // Dispatch map-ready event for other controllers with a small delay
      // to ensure all layers are fully processed
      setTimeout(() => {
        if (map && map.loaded()) {
          document.dispatchEvent(new CustomEvent('map:ready', {
            detail: { map: map }
          }));
        }
      }, 100);
    });

    const resetIsochrones = async () => {
      map.getSource("isochrones-3600").setData(await fetchIsochrone(3600));
      map.getSource("isochrones-1800").setData(await fetchIsochrone(1800));
      map.getSource("isochrones-900").setData(await fetchIsochrone(900));
    };

    const resetPaths = async () => {
      if (!map.getSource("paths")) {
        return;
      }

      map.getSource("paths").setData(await fetchPaths());
    }

    const addPaths = async () => {
      let data = await fetchPaths();

      map.addSource("paths", {
        type: "geojson",
        data: data,
      });

      // Add invisible wider layer for click detection
      map.addLayer(
        {
          id: "paths-clickable",
          type: "line",
          source: "paths",
          paint: {
            "line-color": "rgba(0,0,0,0)", // Transparent
            "line-width": 12, // Much wider for easier clicking
            "line-opacity": 0,
          },
        },
        firstSymbolId,
      );

      // Add visible layer on top
      map.addLayer(
        {
          id: "paths",
          type: "line",
          source: "paths",
          paint: {
            "line-color": "#274c77",
            "line-width": 2,
            "line-opacity": 0.9,
          },
        },
        firstSymbolId,
      );
    };

    const fetchPaths = async () => {
      const zoom = Math.round(map.getZoom());
      const bounds = map.getBounds().toArray().flat().join(",");
      const response = await fetch(`api/paths?zoom=${zoom}&bounds=${bounds}`);
      return await response.json();
    };

    document.addEventListener("enabled-filter:tracks", async () => {
      await addPaths();
      // Dispatch event for GPX tracks controller to set up interactions
      document.dispatchEvent(new CustomEvent("gpx-tracks:paths-loaded"));
    });

    document.addEventListener("disabled-filter:tracks", async () => {
      map.removeLayer("paths");
      map.removeLayer("paths-clickable");
      map.removeSource("paths");
    });

    const fetchAccommodations = async () => {
      const bounds = map.getBounds().toArray().flat().join(",");
      const response = await fetch(`api/accommodations?bounds=${bounds}`);
      return await response.json();
    };

    const addAccommodations = async () => {
      let data = await fetchAccommodations();

      if (!map.hasImage('bed-icon')) {
        const size = 48; // Higher resolution for crisp rendering
        const canvas = document.createElement('canvas');
        const ctx = canvas.getContext('2d');
        canvas.width = size;
        canvas.height = size;

        // Create SVG string - keep viewBox at 24 but render at higher resolution
        const bedSvg = `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" d="M9.293 2.293a1 1 0 0 1 1.414 0l7 7A1 1 0 0 1 17 11h-1v6a1 1 0 0 1-1 1h-2a1 1 0 0 1-1-1v-3a1 1 0 0 0-1-1H9a1 1 0 0 0-1 1v3a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-6H3a1 1 0 0 1-.707-1.707l7-7Z" fill="#E66A5F" stroke="white" stroke-width="1.5" clip-rule="evenodd"></path></svg>`;

        const img = new Image();
        img.onload = function() {
          ctx.drawImage(img, 0, 0, size, size);
          const imageData = ctx.getImageData(0, 0, size, size);
          map.addImage('bed-icon', imageData, { pixelRatio: 2 });
        };
        img.src = 'data:image/svg+xml;base64,' + btoa(bedSvg);
      }

      map.addSource("accommodations", {
        type: "geojson",
        data: data,
      });

      map.addLayer(
        {
          id: "accommodations",
          type: "symbol",
          source: "accommodations",
          layout: {
            "icon-image": "bed-icon",
            "icon-size": 0.7,
            "icon-anchor": "center",
            "icon-allow-overlap": true,
            "icon-ignore-placement": true,
          },
        },
        firstSymbolId,
      );

      map.on("click", "accommodations", (e) => {
        e.preventDefault();
        const properties = e.features[0].properties;
        const coordinates = e.features[0].geometry.coordinates.slice();
        const images = JSON.parse(properties.images || '[]');
        const firstImage = images.length > 0 ? images[0] : null;

        new maplibregl.Popup({
          className: 'accommodation-popup',
          maxWidth: '288px',
          closeButton: false,
        })
          .setLngLat(coordinates)
          .setHTML(`
            <div class="rounded-2xl w-72 bg-white shadow-lg font-body overflow-hidden">
              ${properties.url ? `<a target="_blank" href="/api/accommodations/${properties.id}">` : '<div>'}
                ${firstImage ? `<img class="h-44 w-full object-cover" src="${firstImage}" alt="${properties.name}">` : '<div class="h-44 w-full bg-gray-200 flex items-center justify-center"><span class="text-gray-400">Pas d\'image</span></div>'}
                <div class="px-3 py-3 text-left">
                  <div class="flex items-center justify-between">
                    <div class="font-semibold text-sm text-gray-600">
                      ${properties.city || ''}
                    </div>
                    <div class="inline-block px-2 py-0.5 rounded-full bg-gray-100 font-medium text-xs text-[#006B52]">${properties.source.charAt(0).toUpperCase() + properties.source.slice(1)}</div>
                  </div>
                  ${properties.price ? `
                    <div class="font-medium my-1 text-xs text-gray-600">
                      Dès <span class="font-bold">${properties.price} €</span> / nuit
                    </div>
                  ` : ''}
                </div>
              ${properties.url ? '</a>' : '</div>'}
            </div>
          `)
          .addTo(map);
      });

      map.on("mouseenter", "accommodations", () => {
        map.getCanvas().style.cursor = "pointer";
      });

      map.on("mouseleave", "accommodations", () => {
        map.getCanvas().style.cursor = "";
      });
    };

    const resetAccommodations = async () => {
      if (!map.getSource("accommodations")) {
        return;
      }

      map.getSource("accommodations").setData(await fetchAccommodations());
    };

    document.addEventListener("enabled-filter:accommodations", async () => {
      addAccommodations();
    });

    document.addEventListener("disabled-filter:accommodations", async () => {
      map.removeLayer("accommodations");
      map.removeSource("accommodations");
    });


    map.on("moveend", async () => {
      resetPaths();
      resetAccommodations();
    });

    map.on("zoomend", async () => {
      if (Math.round(map.getZoom()) > 9 && zoomLevel < 9) {
        resetIsochrones();
      }

      if (Math.round(map.getZoom()) < 9 && zoomLevel > 9) {
        resetIsochrones();
      }

      zoomLevel = map.getZoom();
    });

    const addAttribution = () => {
      map.addSource('attribution', {
        type: 'geojson',
        data: {
          type: 'FeatureCollection',
          features: []
        },
        attribution: 'Les collectivités contributrices de l’Observatoire national des véloroutes, <a href="https://reseau-velo-marche.org/">Réseau vélo et marche</a>'
      });

      map.addLayer({
        id: 'attribution',
        type: 'symbol',
        source: 'attribution',
        layout: {
        },
      });
    }
  }
}
