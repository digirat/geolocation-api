# syntax=docker/dockerfile:1
FROM ruby:3.4.6-slim

# + libyaml-dev and pkg-config so psych can build
RUN apt-get update -y && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  git \
  curl \
  ca-certificates \
  pkg-config \
  libyaml-dev \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

ENV APP_HOME=/app \
    BUNDLE_PATH=/usr/local/bundle \
    RAILS_ENV=development \
    RACK_ENV=development

WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

RUN chmod +x bin/docker-entrypoint
ENTRYPOINT ["bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
