import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

/**
 * Minimal map controller - only handles Leaflet-specific functionality.
 * Modal uses native <dialog> element (ERB template) with showModal()/close().
 */
export default class extends Controller {
  static values = { visitsUrl: String, createUrl: String }

  connect() {
    this.#ensureLeafletCss()
    this.icon = this.#markerIcon()

    // Define world bounds to prevent infinite horizontal scrolling
    const worldBounds = L.latLngBounds(
      L.latLng(-85, -180), // Southwest corner
      L.latLng(85, 180)    // Northeast corner
    )

    this.map = L.map(this.element, {
      scrollWheelZoom: true,
      maxBounds: worldBounds,
      maxBoundsViscosity: 1.0,
      minZoom: 2
    }).setView([20, 0], 2)

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors",
      noWrap: true,
      bounds: worldBounds
    }).addTo(this.map)

    this.#loadExistingVisits()
    this.map.on("click", (e) => this.#handleClick(e))

    // Handle form submission from dialog
    const form = document.getElementById("add-visit-form")
    if (form) {
      form.addEventListener("submit", (e) => this.#handleFormSubmit(e))
    }
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

  async #loadExistingVisits() {
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

  #handleClick(e) {
    const dialog = document.getElementById("add-visit-modal")
    const latField = document.getElementById("add-visit-lat")
    const lonField = document.getElementById("add-visit-lon")
    if (latField) latField.value = e.latlng.lat
    if (lonField) lonField.value = e.latlng.lng
    // Clear previous form values
    document.getElementById("add-visit-name").value = ""
    document.getElementById("add-visit-date").value = ""
    document.getElementById("add-visit-notes").value = ""
    dialog?.showModal()
  }

  async #handleFormSubmit(e) {
    e.preventDefault()
    const form = e.target
    const dialog = document.getElementById("add-visit-modal")
    
    const formData = new FormData(form)
    const payload = new URLSearchParams()
    for (const [key, value] of formData.entries()) {
      if (value) payload.append(key, value)
    }

    try {
      const resp = await fetch(this.createUrlValue, {
        method: "POST",
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/x-www-form-urlencoded",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: payload.toString()
      })

      if (resp.ok) {
        const visit = await resp.json()
        this.#addMarker(visit)
        this.#refreshTable()
        dialog?.close()
      }
    } catch (error) {
      console.error("Failed to create visit:", error)
    }
  }

  #addMarker(v) {
    const marker = L.marker([v.lat, v.lon], { icon: this.icon }).addTo(this.map)
    const name = v.place_name || "Visited"
    const cc = v.country_code ? ` (${v.country_code})` : ""
    const date = v.visited_on ? `<br><small>Visited: ${v.visited_on}</small>` : ""
    const notes = v.notes ? `<br><small>${this.#esc(v.notes)}</small>` : ""
    marker.bindPopup(`<strong>${this.#esc(name)}${cc}</strong>${date}${notes}<br><small class="text-gray-500">Right-click to delete</small>`)
    if (v.id) marker.on("contextmenu", (ev) => this.#confirmDelete(ev, marker, v.id))
  }

  async #confirmDelete(ev, marker, id) {
    if (!ev.originalEvent?.ctrlKey && !confirm("Delete this visit? (Ctrl+right-click skips this)")) return
    const csrf = document.querySelector('meta[name="csrf-token"]')?.content
    const resp = await fetch(`/visits/${id}`, { method: "DELETE", headers: { "X-CSRF-Token": csrf } })
    if (resp.ok) {
      this.map.removeLayer(marker)
      this.#refreshTable()
    }
  }

  async #refreshTable() {
    const container = document.getElementById("visits-list")
    if (!container) return
    try {
      const resp = await fetch("/visits/list", { headers: { Accept: "text/html" } })
      if (resp.ok) {
        container.innerHTML = await resp.text()
        container.classList.remove("hidden")
      }
    } catch (_) {}
  }

  #markerIcon() {
    const svg = encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41"><path fill="#2d6cdf" d="M12.5 0C5.6 0 0 5.6 0 12.5c0 9.3 12.5 28.5 12.5 28.5S25 21.8 25 12.5C25 5.6 19.4 0 12.5 0z"/><circle cx="12.5" cy="12.5" r="5.5" fill="#fff"/></svg>`)
    return L.icon({ iconUrl: `data:image/svg+xml;charset=UTF-8,${svg}`, iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [0, -36] })
  }

  #esc(s) { return String(s).replace(/&/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;") }
}
