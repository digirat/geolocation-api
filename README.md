# Geolocation API (Rails)

A simple RESTful API for storing and retrieving geolocation data based on IP address or URL.
It uses [ipstack](https://ipstack.com/) as the geolocation provider, but the provider is pluggable so it can be swapped out later.

## Features
- Rails 8 API-only application
- PostgreSQL for persistence
- Geolocation lookups via ipstack
- JSON:API-compliant input/output
- RSpec test suite
- Docker + Docker Compose for easy setup
- Optional API key authentication (`X-API-Key` header)

---

## Requirements
- [Docker](https://docs.docker.com/get-docker/)
- [Docker Compose](https://docs.docker.com/compose/)

*(Optional)* If you want to run locally without Docker:
- Ruby 3.4+
- PostgreSQL 15+

---

## Setup with Docker (recommended)

1. Clone the repository:
   ```bash
   git clone https://github.com/digirat/geolocation-api.git
   cd geolocation-api
   ```

2. Copy the example environment file:
   ```bash
   cp .env.docker.example .env.docker
   ```

3. Edit `.env.docker` and set your **ipstack API key**:
   ```dotenv
   IPSTACK_API_KEY=your_real_key_here
   ```

4. Build and run the stack:
   ```bash
   docker compose up --build
   ```

5. The API will be available at:
   ```
   http://localhost:3000
   ```

---

## Example Usage

### Create a geolocation record
```bash
curl -X POST http://localhost:3000/geolocations \
  -H 'Content-Type: application/json' \
  -H 'X-API-Key: secret' \
  -d '{"data":{"type":"geolocations","attributes":{"query":"8.8.8.8"}}}'
```

### List geolocations
```bash
curl -H 'X-API-Key: secret' http://localhost:3000/geolocations
```

### Show a single geolocation
```bash
curl -H 'X-API-Key: secret' http://localhost:3000/geolocations/8.8.8.8
```

### Delete a geolocation
```bash
curl -X DELETE -H 'X-API-Key: secret' http://localhost:3000/geolocations/8.8.8.8
```

---

## Running Tests

Inside Docker:
```bash
docker compose run --rm web bin/rails spec
```

Locally (if you prefer):
```bash
bundle exec rspec
```

---

## Running Locally (without Docker)

1. Install dependencies:
   ```bash
   bundle install
   ```

2. Set up PostgreSQL and environment variables (example `.envrc` for direnv):
   ```bash
   export POSTGRESQL_USERNAME=postgres
   export POSTGRESQL_PASSWORD=yourpassword
   export POSTGRESQL_ADDRESS=localhost
   export POSTGRESQL_DB=geolocation_dev
   export POSTGRESQL_TEST_DB=geolocation_test
   export POSTGRESQL_PROD_DB=geolocation_prod

   export IPSTACK_API_KEY=your_real_key_here
   export IPSTACK_BASE_URL=http://api.ipstack.com
   export GEO_PROVIDER=ipstack
   export API_KEY=secret
   export CORS_ORIGINS=*
   ```

3. Prepare the database:
   ```bash
   bin/rails db:prepare
   ```

4. Start the server:
   ```bash
   bin/rails s
   ```

---

## Notes
- All endpoints require the header:
  ```
  X-API-Key: secret
  ```
  (configurable in your env file)
- By default, CORS is open (`*`). Restrict it by setting `CORS_ORIGINS` in your environment.
- If you change DB credentials in `.env.docker`, delete volumes with `docker compose down -v` and re-run.

---

## License
MIT
