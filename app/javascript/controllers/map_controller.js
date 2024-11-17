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
        id: "train_station_labels_A",
        type: "symbol",
        source: "train_stations",
        layout: {
          "text-field": ["get", "name"],
          "text-font": ["Noto Sans Medium"],
          "text-size": 12,
          "text-anchor": "bottom",
        },
        minzoom: 7,
        filter: ["==", ["get", "drg"], "A"], // Filter to display only features with drg property of "A"
        paint: {
          "text-color": "#333",
          "text-halo-color": "rgba(255,255,255,0.5)",
          "text-halo-width": 1,
        },
      });

      map.addLayer({
        id: "train_station_labels_B",
        type: "symbol",
        source: "train_stations",
        layout: {
          "text-field": ["get", "name"],
          "text-font": ["Noto Sans Medium"],
          "text-size": 12,
          "text-anchor": "bottom",
        },
        minzoom: 9, // This layer will be visible from zoom level 10 and above
        filter: ["==", ["get", "drg"], "B"], // Filter to display features with drg property of "A" or "B"
        paint: {
          "text-color": "#333",
          "text-halo-color": "rgba(255,255,255,0.5)",
          "text-halo-width": 1,
        },
      });

      map.addLayer({
        id: "train_station_labels_C",
        type: "symbol",
        source: "train_stations",
        layout: {
          "text-field": ["get", "name"],
          "text-font": ["Noto Sans Medium"],
          "text-size": 12,
          "text-anchor": "bottom",
        },
        minzoom: 10,
        filter: ["==", ["get", "drg"], "C"], // Filter to display features with drg property of "A" or "B"
        paint: {
          "text-color": "#333",
          "text-halo-color": "rgba(255,255,255,0.5)",
          "text-halo-width": 1,
        },
      });

      // Add click event listener to the train stations layer
      map.on("click", "train_station_labels_A", async function (e) {
        await placeMarker(e);
      });

      map.on("click", "train_station_labels_B", async function (e) {
        await placeMarker(e);
      });

      map.on("click", "train_station_labels_C", async function (e) {
        await placeMarker(e);
      });

      async function placeMarker(e) {
        const coordinates = e.features[0].geometry.coordinates.slice();

        // get station information from api, based on the name
        let station = await fetch(
          `api/train_stations/${e.features[0].properties.name}`,
        );

        if (!station.ok) {
          return;
        }

        station = await station.json();

        new maplibregl.Popup()
          .setLngLat(coordinates)
          .setHTML(
            `<h3 class="font-bold">${station.name}</h3>
            <p class="text-xs my-1">${
              station.trains_per_day
            } trains aujourd'hui</p>
            <ul class="flex flex-wrap gap-1 flex-start">
            ${station.lines
              .map(
                (line) =>
                  `<li class="py-px px-2 font-medium text-xs rounded" style="background-color: #${line.bg_color}; color: #${line.text_color}">${line.short_name}</li>`,
              )
              .join("")}
            </ul>
            `,
          )
          .addTo(map);
      }

      map.on("mouseenter", "train_station_labels", function () {
        map.getCanvas().style.cursor = "pointer";
      });

      map.on("mouseleave", "train_station_labels", function () {
        map.getCanvas().style.cursor = "";
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
