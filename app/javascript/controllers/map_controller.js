import { Controller } from "@hotwired/stimulus"
import * as L from "leaflet"

// Connects to data-controller="map"
export default class extends Controller {
  static values = {
    visitsUrl: String,
    createUrl: String
  }

  connect() {
    // Include Leaflet CSS
    this.#ensureLeafletCss()

    // Use an inline SVG icon so pins always render without fetching external images
    this.icon = this.#markerIcon()

    this.map = L.map(this.element, { scrollWheelZoom: true }).setView([20, 0], 2)
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(this.map)

    this.#loadExistingVisits()

    // Store bound click handler for cleanup
    this._handleMapClick = (e) => this.#handleClick(e)
    this.map.on("click", this._handleMapClick)
  }

  disconnect() {
    // Clean up map resources to prevent memory leaks
    if (this.map) {
      this.map.off("click", this._handleMapClick)
      this.map.remove()
      this.map = null
    }
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
      const resp = await fetch(this.visitsUrlValue, { headers: { "Accept": "application/json" } })
      if (!resp.ok) return
      const data = await resp.json()
      let first = true
      const list = document.getElementById('visits-list')
      if (list) list.innerHTML = ''
      for (const v of data.visits || []) {
        if (v.lat && v.lon) {
          const marker = L.marker([v.lat, v.lon], { icon: this.icon }).addTo(this.map)
          marker.bindPopup(this.#buildPopupContent(v))
          if (v.id) {
            marker.on("contextmenu", (ev) => this.#confirmAndDelete(ev, marker, v.id))
            marker.on("popupopen", (ev) => this.#attachPopupActions(ev.popup, v, marker))
          }
          if (first) {
            this.map.setView([v.lat, v.lon], 6)
            first = false
          }
          // append to list
          if (list) { this.#refreshTable(list) }
        }
      }
    } catch (_) { /* no-op */ }
  }

  async #handleClick(e) {
    const { lat, lng } = e.latlng
    const details = await this.#openModalForDetails(lat, lng)
    if (details === null) return // cancelled
    const payload = new URLSearchParams({ lat: lat.toString(), lon: lng.toString(), ...details })
    try {
      const resp = await fetch(this.createUrlValue, {
        method: "POST",
        headers: { "Accept": "application/json", "Content-Type": "application/x-www-form-urlencoded", "X-CSRF-Token": this.#getCsrfToken() },
        body: payload.toString(),
        credentials: "same-origin"
      })
      if (!resp.ok) return
      const data = await resp.json()
      if (data.lat && data.lon) {
        const marker = L.marker([data.lat, data.lon], { icon: this.icon }).addTo(this.map)
        marker.bindPopup(this.#buildPopupContent(data))
        marker.on("contextmenu", (ev) => this.#confirmAndDelete(ev, marker, data.id))
        marker.on("popupopen", (ev) => this.#attachPopupActions(ev.popup, data, marker))
        this.#appendToList(data)
      }
    } catch (_) { /* no-op */ }
  }

  async #deleteMarker(marker, id) {
    const resp = await fetch(`/visits/${id}`, { method: "DELETE", headers: { "X-CSRF-Token": this.#getCsrfToken() } })
    if (resp.ok) {
      this.map.removeLayer(marker)
    }
  }

  #confirmAndDelete(ev, marker, id) {
    // If Control is held, skip confirm
    if (!ev.originalEvent?.ctrlKey) {
      const ok = window.confirm("Are you sure you want to delete this visit? You can also delete with control + right-click.")
      if (!ok) return
    }
    this.#deleteMarker(marker, id)
  }

  #buildPopupContent(data) {
    const name = data.place_name || "Visited place"
    const cc = data.country_code ? ` (${data.country_code})` : ""
    const date = data.visited_on ? `<div><strong>Visited:</strong> ${data.visited_on}</div>` : ""
    const notes = data.notes ? `<div style="max-width:220px;"><strong>Notes:</strong> ${this.#escapeHtml(data.notes)}</div>` : ""
    const edit = data.id ? `<div style=\"margin-top:8px;\"><button data-action=\"click->map#editVisit\" data-visit-id=\"${data.id}\" style=\"padding:6px 10px;border:none;border-radius:6px;background:#10b981;color:#fff;\">Edit details</button></div>` : ""
    return `<div><div><strong>${this.#escapeHtml(name)}${cc}</strong></div>${date}${notes}${edit}<div style="margin-top:6px;color:#6b7280;">Right-click to delete</div></div>`
  }

  #escapeHtml(str) {
    return String(str)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }

  async editVisit(event) {
    const id = event.currentTarget.dataset.visitId
    // fetch current values to prefill
    let current = { visited_on: "", notes: "" }
    try {
      const r = await fetch(this.visitsUrlValue, { headers: { "Accept": "application/json" } })
      if (r.ok) {
        const j = await r.json()
        const m = (j.visits || []).find(v => String(v.id) === String(id))
        if (m) current = { visited_on: m.visited_on || "", notes: m.notes || "" }
      }
    } catch (_) {}
    const overlay = document.createElement("div")
    overlay.style.position = "fixed"
    overlay.style.inset = 0
    overlay.style.background = "rgba(0,0,0,0.4)"
    overlay.style.zIndex = 2000

    const modal = document.createElement("div")
    modal.style.position = "absolute"
    modal.style.top = "50%"
    modal.style.left = "50%"
    modal.style.transform = "translate(-50%, -50%)"
    modal.style.background = "#fff"
    modal.style.padding = "16px"
    modal.style.borderRadius = "8px"
    modal.style.width = "min(90vw, 420px)"
    modal.innerHTML = `
      <h3 style="font-weight:600;margin-bottom:8px;">Edit Visit</h3>
      <div style="display:flex;flex-direction:column;gap:8px;">
        <label>Visited on<input id="edit-date" type="date" value="${current.visited_on}" style="width:100%;padding:8px;border:1px solid #ccc;border-radius:6px;"></label>
        <label>Notes<textarea id="edit-notes" rows="3" style="width:100%;padding:8px;border:1px solid #ccc;border-radius:6px;">${this.#escapeHtml(current.notes)}</textarea></label>
        <div style="display:flex;justify-content:flex-end;gap:8px;margin-top:8px;">
          <button id="edit-cancel" style="padding:8px 12px;border:1px solid #ccc;border-radius:6px;background:#f9fafb;">Cancel</button>
          <button id="edit-save" style="padding:8px 12px;border:none;border-radius:6px;background:#2563eb;color:#fff;">Save</button>
        </div>
      </div>`
    overlay.appendChild(modal)
    document.body.appendChild(overlay)

    overlay.querySelector('#edit-cancel').onclick = () => document.body.removeChild(overlay)
    overlay.querySelector('#edit-save').onclick = async () => {
      const visited_on = overlay.querySelector('#edit-date').value
      const notes = overlay.querySelector('#edit-notes').value
      const body = new URLSearchParams({ visited_on, notes })
      const resp = await fetch(`/visits/${id}`, { method: 'PATCH', headers: { 'X-CSRF-Token': this.#getCsrfToken(), 'Content-Type': 'application/x-www-form-urlencoded', 'Accept': 'application/json' }, body: body.toString() })
      if (resp.ok) {
        document.body.removeChild(overlay)
      }
    }
  }

  #attachPopupActions(_popup, _data, _marker) {
    // not used; actions are bound via data-action
  }

  #appendToList(v) {
    const list = document.getElementById('visits-list')
    if (!list) return
    this.#refreshTable(list)
  }

  async #refreshTable(container) {
    try {
      const resp = await fetch('/visits/list', { headers: { 'Accept': 'text/html' } })
      if (!resp.ok) return
      const html = await resp.text()
      container.innerHTML = html
      container.classList.remove('hidden')
    } catch (_) { /* no-op */ }
  }

  #markerIcon() {
    const svg = encodeURIComponent(`
      <svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41">
        <path fill="#2d6cdf" d="M12.5 0C5.6 0 0 5.6 0 12.5c0 9.3 12.5 28.5 12.5 28.5S25 21.8 25 12.5C25 5.6 19.4 0 12.5 0z"/>
        <circle cx="12.5" cy="12.5" r="5.5" fill="#fff"/>
      </svg>`)
    return L.icon({ iconUrl: `data:image/svg+xml;charset=UTF-8,${svg}`, iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [0, -36] })
  }

  #openModalForDetails(lat, lon) {
    return new Promise((resolve) => {
      const overlay = document.createElement("div")
      overlay.style.position = "fixed"
      overlay.style.inset = 0
      overlay.style.background = "rgba(0,0,0,0.4)"
      overlay.style.zIndex = 2000

      const modal = document.createElement("div")
      modal.style.position = "absolute"
      modal.style.top = "50%"
      modal.style.left = "50%"
      modal.style.transform = "translate(-50%, -50%)"
      modal.style.background = "#fff"
      modal.style.padding = "16px"
      modal.style.borderRadius = "8px"
      modal.style.width = "min(90vw, 420px)"
      modal.innerHTML = `
        <h3 style="font-weight:600;margin-bottom:8px;">Add Visit</h3>
        <div style="display:flex;flex-direction:column;gap:8px;">
          <label>Name (optional)<input id="visit-name" type="text" style="width:100%;padding:8px;border:1px solid #ccc;border-radius:6px;"></label>
          <label>Visited on (optional)<input id="visit-date" type="date" style="width:100%;padding:8px;border:1px solid #ccc;border-radius:6px;"></label>
          <label>Notes (optional)<textarea id="visit-notes" rows="3" style="width:100%;padding:8px;border:1px solid #ccc;border-radius:6px;"></textarea></label>
          <div style="display:flex;justify-content:flex-end;gap:8px;margin-top:8px;">
            <button id="visit-cancel" style="padding:8px 12px;border:1px solid #ccc;border-radius:6px;background:#f9fafb;">Cancel</button>
            <button id="visit-save" style="padding:8px 12px;border:none;border-radius:6px;background:#2563eb;color:#fff;">Save</button>
          </div>
        </div>`

      overlay.appendChild(modal)
      document.body.appendChild(overlay)

      overlay.querySelector('#visit-cancel').onclick = () => { document.body.removeChild(overlay); resolve(null) }
      overlay.querySelector('#visit-save').onclick = () => {
        const name = overlay.querySelector('#visit-name').value.trim()
        const visited_on = overlay.querySelector('#visit-date').value
        const notes = overlay.querySelector('#visit-notes').value.trim()
        document.body.removeChild(overlay)
        resolve({ ...(name ? { name } : {}), ...(visited_on ? { visited_on } : {}), ...(notes ? { notes } : {}) })
      }
    })
  }

  #getCsrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}


