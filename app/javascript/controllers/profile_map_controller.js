import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

/**
 * Read-only map controller for viewing other users' travel profiles.
 * Displays markers without any edit/delete/create functionality.
 */
export default class extends Controller {
  static values = { visitsUrl: String }

  connect() {
    this.#ensureLeafletCss()
    this.icon = this.#markerIcon()

    this.map = L.map(this.element, { scrollWheelZoom: true }).setView([20, 0], 2)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    this.#loadVisits()
  }

  disconnect() {
    this.map?.remove()
    this.map = null
  }

  #ensureLeafletCss() {
    if (document.getElementById("leaflet-css")) return
    const link = document.createElement("link")
    link.id = "leaflet-css"
    link.rel = "stylesheet"
    link.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
    document.head.appendChild(link)
  }

  async #loadVisits() {
    try {
      const resp = await fetch(this.visitsUrlValue, { headers: { Accept: "application/json" } })
      if (!resp.ok) return
      const data = await resp.json()
      let first = true
      for (const v of data.visits || []) {
        if (v.lat && v.lon) {
          this.#addMarker(v)
          if (first) { this.map.setView([v.lat, v.lon], 6); first = false }
        }
      }
    } catch (_) {}
  }

  #addMarker(v) {
    const marker = L.marker([v.lat, v.lon], { icon: this.icon }).addTo(this.map)
    const name = v.place_name || "Visited"
    const cc = v.country_code ? ` (${v.country_code})` : ""
    const date = v.visited_on ? `<br><small>Visited: ${v.visited_on}</small>` : ""
    const notes = v.notes ? `<br><small>${this.#esc(v.notes)}</small>` : ""
    marker.bindPopup(`<strong>${this.#esc(name)}${cc}</strong>${date}${notes}`)
  }

  #markerIcon() {
    const svg = encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41"><path fill="#2d6cdf" d="M12.5 0C5.6 0 0 5.6 0 12.5c0 9.3 12.5 28.5 12.5 28.5S25 21.8 25 12.5C25 5.6 19.4 0 12.5 0z"/><circle cx="12.5" cy="12.5" r="5.5" fill="#fff"/></svg>`)
    return L.icon({ iconUrl: `data:image/svg+xml;charset=UTF-8,${svg}`, iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [0, -36] })
  }

  #esc(s) { return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;") }
}

