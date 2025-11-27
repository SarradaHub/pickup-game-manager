json.extract!(payment, :id, :date, :status, :athlete_id, :match_id, :description, :amount, :created_at, :updated_at)
json.url(payment_url(payment, format: :json))
