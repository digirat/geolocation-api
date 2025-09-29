class CreateGeolocations < ActiveRecord::Migration[8.0]
  def change
    create_table :geolocations do |t|
      t.string :query, null: false
      t.string :ip
      t.string :url
      t.string :city
      t.string :region
      t.string :country
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :provider, null: false, default: "ipstack"
      t.string :status, null: false, default: "ok"
      t.jsonb :raw, null: false, default: {}

      t.timestamps
    end
    add_index :geolocations, :query, unique: true
    add_index :geolocations, :ip
    add_index :geolocations, :url
  end
end
