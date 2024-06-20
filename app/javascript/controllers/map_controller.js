import maplibregl from "maplibre-gl";
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    var map = new maplibregl.Map({
      container: "map", // container id
      style:
        "https://api.maptiler.com/maps/basic-v2/style.json?key=kuj5v1XwJShznVUAIGz3", // style URL
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
            "line-width": 1.2,
            "line-opacity": 0.8,
          },
        },
        firstSymbolId,
      );
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

      map.addLayer({
        id: "train_lines_labels",
        type: "symbol",
        source: "train_stations",
        layout: {
          "text-field": ["get", "name"],
          "text-font": ["Noto Sans Bold"],
          "text-size": 12,
          "text-anchor": "bottom",
        },
        minzoom: 8,
        paint: {
          "text-color": "#333",
          "text-halo-color": "rgba(255,255,255,0.5)",
          "text-halo-width": 1,
        },
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
    });

    const resetIsochrones = async () => {
      map.getSource("isochrones-3600").setData(await fetchIsochrone(3600));
      map.getSource("isochrones-1800").setData(await fetchIsochrone(1800));
      map.getSource("isochrones-900").setData(await fetchIsochrone(900));
    };

    map.on("zoomend", async () => {
      if (Math.round(map.getZoom()) > 9 && zoomLevel < 9) {
        resetIsochrones();
        zoomLevel = map.getZoom();
      }

      if (Math.round(map.getZoom()) < 9 && zoomLevel > 9) {
        resetIsochrones();
        zoomLevel = map.getZoom();
      }
    });
  }
}
