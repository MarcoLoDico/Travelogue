require "test_helper"

class VisitsControllerTest < ActionDispatch::IntegrationTest
  test "index requires auth and returns visits" do
    user = users(:alice)
    sign_in_user(user)
    get visits_path, headers: { "Accept" => "application/json" }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["visits"].is_a?(Array)
    # Should include extended fields
    if body["visits"].first
      v = body["visits"].first
      assert_includes v.keys, "place_name"
      assert_includes v.keys, "country_code"
      assert_includes v.keys, "notes"
    end
  end

  test "create adds a visit at clicked point" do
    user = users(:alice)
    sign_in_user(user)
    assert_difference -> { user.visits.count }, +1 do
      post visits_path, params: { lat: 43.7, lon: -79.4 }, headers: { "Accept" => "application/json" }
      assert_response :success
    end
    data = JSON.parse(response.body)
    assert_in_delta 43.7, data["lat"].to_f, 0.0001
    assert_in_delta -79.4, data["lon"].to_f, 0.0001
  end

  test "create with custom name still determines country_code automatically via geocoding" do
    user = users(:alice)
    sign_in_user(user)

    # Stub Nominatim reverse geocoding API to return a known country code
    stub_request(:get, %r{nominatim\.openstreetmap\.org/reverse})
      .to_return(
        status: 200,
        body: {
          "address" => { "city" => "Berlin", "country_code" => "de" },
          "display_name" => "Berlin, Germany"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference -> { user.visits.count }, +1 do
      post visits_path,
           params: { lat: 52.52, lon: 13.405, name: "My Custom Place Name" },
           headers: { "Accept" => "application/json" }
      assert_response :success
    end

    data = JSON.parse(response.body)
    # Name should be the user-provided custom name
    assert_equal "My Custom Place Name", data["place_name"]
    # Country code should come from the geocoder (uppercased), NOT from user input
    assert_equal "DE", data["country_code"]
  end

  test "update changes notes and visited_on" do
    user = users(:alice)
    sign_in_user(user)
    # create one
    post visits_path, params: { lat: 43.7, lon: -79.4 }, headers: { "Accept" => "application/json" }
    visit_id = JSON.parse(response.body)["id"]
    patch visit_path(visit_id), params: { notes: "Great place", visited_on: Date.today.to_s }, headers: { "Accept" => "application/json" }
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Great place", body["notes"]
    assert_equal Date.today.to_s, body["visited_on"]
  end

  test "destroy removes visit" do
    user = users(:alice)
    sign_in_user(user)
    post visits_path, params: { lat: 43.7, lon: -79.4 }, headers: { "Accept" => "application/json" }
    visit_id = JSON.parse(response.body)["id"]
    assert_difference -> { user.visits.count }, -1 do
      delete visit_path(visit_id)
      assert_response :no_content
    end
  end

  test "export endpoints return data" do
    user = users(:alice)
    sign_in_user(user)
    get export_visits_path(format: :json)
    assert_response :success
    assert JSON.parse(response.body).is_a?(Array) || JSON.parse(response.body).is_a?(Hash)

    get export_visits_path(format: :csv)
    assert_response :success
    assert_match /id,name,country_code,lat,lon,visited_on,notes/, response.body

    get export_visits_path(format: :kml)
    assert_response :success
    assert_match /<kml/, response.body
  end
end
