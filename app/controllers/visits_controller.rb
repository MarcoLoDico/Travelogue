require "net/http"
require "json"
require "csv"

class VisitsController < ApplicationController
  before_action :require_authentication

  # GET /visits
  def index
    visits = Current.user.visits.includes(:place).order(created_at: :desc)
    render json: {
      visits: visits.map { |v| { id: v.id, lat: v.lat || v.place&.lat, lon: v.lon || v.place&.lon, place_name: v.place&.name, country_code: v.place&.country_code, notes: v.notes, visited_on: v.visited_on } }
    }
  end

  # GET /visits/list (HTML partial table for Turbo replace)
  def list
    @user_places = Current.user.visits.includes(:place).order(created_at: :desc)
    render partial: "visits/table", formats: :html
  end

  # POST /visits
  def create
    lat = params[:lat].to_f
    lon = params[:lon].to_f
    name = params[:name].presence
    visited_on = params[:visited_on].presence
    notes = params[:notes].presence

    # Optional reverse geocoding via Nominatim (OSM) when fields not provided
    country_code = nil
    if name.blank?
      begin
        uri = URI("https://nominatim.openstreetmap.org/reverse")
        uri.query = URI.encode_www_form(format: "jsonv2", lat: lat, lon: lon)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        req = Net::HTTP::Get.new(uri.request_uri)
        req["User-Agent"] = "Travelogue/1.0 (contact: support@travelogue.local)"
        resp = http.request(req).body
        data = JSON.parse(resp) rescue {}
        name = data.dig("address", "city") || data.dig("address", "town") || data.dig("address", "village") || data["display_name"]
        country_code = data.dig("address", "country_code")&.upcase
      rescue StandardError
        # ignore failures
      end
    end

    place = Place.create!(name: name || "Dropped Pin", kind: 1, country_code: country_code, lat: lat, lon: lon)
    visit = Current.user.visits.create!(place: place, lat: lat, lon: lon, source: "manual", visited_on: visited_on, notes: notes)
    render json: { id: visit.id, lat: visit.lat, lon: visit.lon, place_name: place.name, country_code: place.country_code, notes: visit.notes, visited_on: visit.visited_on }
  end

  # DELETE /visits/:id
  def destroy
    visit = Current.user.visits.find(params[:id])
    visit.destroy
    head :no_content
  end

  # PATCH/PUT /visits/:id
  def update
    visit = Current.user.visits.includes(:place).find(params[:id])
    visit.update!(notes: params[:notes], visited_on: params[:visited_on])
    render json: { id: visit.id, notes: visit.notes, visited_on: visit.visited_on }
  end

  # GET /visits/export
  def export
    visits = Current.user.visits.includes(:place).order(visited_on: :asc)
    respond_to do |format|
      format.json { render json: visits.as_json(include: { place: { only: %i[name country_code lat lon] } }, only: %i[id visited_on notes lat lon]) }
      format.csv do
        csv = CSV.generate do |rows|
          rows << %w[id name country_code lat lon visited_on notes]
          visits.each do |v|
            rows << [ v.id, v.place&.name, v.place&.country_code, v.lat || v.place&.lat, v.lon || v.place&.lon, v.visited_on, v.notes ]
          end
        end
        send_data csv, filename: "travelogue_visits.csv", type: "text/csv"
      end
      format.kml do
        kml = <<~KML
          <?xml version="1.0" encoding="UTF-8"?>
          <kml xmlns="http://www.opengis.net/kml/2.2">
            <Document>
              <name>Travelogue Visits</name>
              #{visits.map { |v| "<Placemark><name>#{ERB::Util.html_escape(v.place&.name || 'Visit')}</name><description>#{ERB::Util.html_escape(v.notes.to_s)}</description><Point><coordinates>#{(v.lon || v.place&.lon).to_f},#{(v.lat || v.place&.lat).to_f},0</coordinates></Point></Placemark>" }.join}\n
            </Document>
          </kml>
        KML
        send_data kml, filename: "travelogue_visits.kml", type: "application/vnd.google-earth.kml+xml"
      end
    end
  end
end
