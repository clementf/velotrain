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
      addPaths();
    });

    document.addEventListener("disabled-filter:tracks", async () => {
      map.removeLayer("paths");
      map.removeSource("paths");
    });


    map.on("moveend", async () => {
      resetPaths();
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
  }
}
