json.extract!(match, :id, :date, :location, :created_at, :updated_at)
json.url(match_url(match, format: :json))
