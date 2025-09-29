module GeoProviders
  class Base
    def fetch(_query) = raise NotImplementedError
  end
end
