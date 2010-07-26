# encoding: utf-8

require "time"

module Geocaching
  # This class is subclass of Array and is used to store all logs
  # that belong to a cache.  It implements the {#fetch_all} method to
  # fetch the information of all logs inside the array.
  class LogsArray < Array
    # Calls {Geocaching::Log#fetch} for each log inside the array.
    #
    # @return [Boolean] Whether all logs could be fetched successfully
    def fetch_all
      each { |log| log.fetch }
      map { |log| log.fetched? }.all?
    end
  end

  # This class represents a cache on geocaching.com.  Altough some
  # information are available without being logged in, most information
  # will only be accessible after a successful login.
  #
  # == Example
  #
  #  cache = Geocaching::Cache.fetch(:code => "GCTEST")
  #  
  #  puts cache.difficulty #=> 3.5
  #  puts cache.latitude #=> 49.741541
  #  puts cache.archived? #=> false
  #
  class Cache
    # Creates a new instance and calls the {#fetch} methods afterwards.
    # One of +:code+ or +:guid+ must be provided as attributes.
    #
    # @param [Hash] attributes A hash of attributes, see {#initialize}
    # @return [Geocaching::Cache]
    # @raise [ArgumentError] Tried to set an unknown attribute
    # @raise [ArgumentError] Neither code nor GUID given
    def self.fetch(attributes)
      cache = new(attributes)
      cache.fetch
      cache
    end

    # Creates a new instance.  The following attributes may be specified
    # as parameters:
    #
    # * +:code+ — The cache’s GC code
    # * +:guid+ — The cache’s Globally Unique Identifier
    #
    # @param [Hash] attributes A hash of attributes
    # @raise [ArgumentError] Trying to set an unknown attribute
    def initialize(attributes = {})
      @data, @doc, @code, @guid = nil, nil, nil, nil

      attributes.each do |key, value|
        if [:code, :guid].include?(key)
          instance_variable_set("@#{key}", value)
        else
          raise ArgumentError, "Trying to set unknown attribute `#{key}'"
        end
      end
    end

    # Fetches cache information from geocaching.com.
    #
    # @return [void]
    # @raise [ArgumentError] Neither code nor GUID are given
    # @raise [Geocaching::TimeoutError] Timeout hit
    # @raise [Geocaching::HTTPError] HTTP request failed
    def fetch
      raise ArgumentError, "Neither code nor GUID given" unless @code or @guid

      resp, @data = HTTP.get(path)
      @doc = Hpricot(@data)
    end

    # Whether information have successfully been fetched
    # from geocaching.com.
    #
    # @return [Boolean] Have information been fetched?
    def fetched?
      @data and @doc
    end

    # The cache’s code (GCXXXXXX).
    #
    # @return [String] Code
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract code from website
    def code
      @code ||= begin
        raise NotFetchedError unless fetched?
        elements = @doc.search("#ctl00_uxWaypointName.GCCode")

        if elements.size == 1 and elements.first.inner_html =~ /(GC[A-Z0-9]+)/
          HTTP.unescape($1)
        else
          raise ExtractError, "Could not extract code from website"
        end
      end
    end

    # The cache’s Globally Unique Identifier.
    #
    # @return [String] GUID
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract GUID from website
    def guid
      @guid ||= begin
        raise NotFetchedError unless fetched?

        elements = @doc.search("#ctl00_ContentBody_lnkPrintFriendly")
        guid = nil

        if elements.size == 1 and href = elements.first.attributes["href"]
          guid = $1 if href =~ /guid=([0-9a-f-]{36})/
        end

        guid || begin
          raise ExtractError, "Could not extract GUID from website"
        end
      end
    end

    # The cache’s type ID.
    #
    # @return [Fixnum] Type ID
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract cache type ID from website
    def type_id
      @type_id ||= begin
        raise NotFetchedError unless fetched?

        if @data =~ /<a.*?title="About Cache Types"><img.*?WptTypes\/(\d+)\.gif".*?<\/a>/
          $1.to_i
        else
          raise ExtractError, "Could not extract cache type ID from website"
        end
      end
    end

    # The cache’s name.
    #
    # @return [String] Name
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract name from website"
    def name
      @name ||= begin
        raise NotFetchedError unless fetched?
        elements = @doc.search("span#ctl00_ContentBody_CacheName")

        if elements.size == 1
          HTTP.unescape(elements.first.inner_html)
        else
          raise ExtractError, "Could not extract name from website"
        end
      end
    end

    # The cache’s difficulty rating.
    #
    # @return [Float] Difficulty rating
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract difficulty rating from website
    def difficulty
      @difficulty ||= begin
        raise NotFetchedError unless fetched?

        if @data =~ /<strong>\s*?Difficulty:<\/strong>\s*?<img.*?alt="([\d\.]{1,3}) out of 5" \/>/
          $1.to_f
        else
          raise ExtractError, "Could not extract difficulty rating from website"
        end
      end
    end

    # The cache’s terrain rating.
    #
    # @return [Float] Terrain rating
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract terrain rating from website
    def terrain
      @terrain ||= begin
        raise NotFetchedError unless fetched?

        if @data =~ /<strong>\s+?Terrain:<\/strong>\s+?<img.*?alt="([\d\.]{1,3}) out of 5" \/>/
          $1.to_f
        else
          raise ExtractError, "Could not extract terrain rating from website"
        end
      end
    end

    # The date the cache has been hidden at.
    #
    # @return [Time] Hidden date
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract hidden date from website
    def hidden_at
      @hidden_at ||= begin
        raise NotFetchedError unless fetched?

        if @data =~ /<strong>\s+?Hidden\s+?:<\/strong>\s+?(\d{1,2})\/(\d{1,2})\/(\d{4})/
          Time.parse([$3, $1, $2].join("-"))
        else
          raise ExtractError, "Could not extract hidden date from website"
        end
      end
    end

    # The cache’s container size.
    #
    # @return [Symbol] Cache container size
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract cache container size from website
    def size
      @size ||= begin
        raise NotFetchedError unless fetched?
        size = nil

        if @data =~ /<img src="\/images\/icons\/container\/(.*?)\.gif" alt="Size: .*?" \/>/
          size = $1.to_sym if %w(micro small regular large other not_chosen).include?($1)
        end

        size || begin
          raise ExtractError, "Could not extract cache container size from website"
        end
      end
    end

    # The cache’s latitude.
    #
    # @return [Float] Latitude
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract latitude from website
    def latitude
      @latitude ||= begin
        raise NotFetchedError unless fetched?

        latitude = nil
        elements = @doc.search("a#ctl00_ContentBody_lnkConversions")

        if elements.size == 1 and href = elements.first.attributes["href"]
          latitude = $1.to_f if href =~ /lat=(-?[0-9\.]+)/
        end

        latitude || begin
          raise ExtractError, "Could not extract latitude from website"
        end
      end
    end

    # The cache’s longitude.
    #
    # @return [Float] Longitude
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract longitude from website
    def longitude
      @longitude ||= begin
        raise NotFetchedError unless fetched?

        longitude = nil
        elements = @doc.search("a#ctl00_ContentBody_lnkConversions")

        if elements.size == 1 and href = elements.first.attributes["href"]
          longitude = $1.to_f if href =~ /lon=(-?[0-9\.]+)/
        end

        longitude || begin
          raise ExtractError, "Could not extract longitude from website"
        end
      end
    end

    # The cache’s location name (State, Country).
    #
    # @return [String] Location name
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract location from website
    def location
      @location ||= begin
        raise NotFetchedError unless fetched?

        location = nil
        elements = @doc.search("span#ctl00_ContentBody_Location")

        if elements.size == 1
          text = @doc.search("span#ctl00_ContentBody_Location").inner_html
          location = $1.strip if text =~ /In ([^<]+)/
        end

        location || begin
          raise ExtractError, "Could not extract location from website"
        end
      end
    end

    # Whether the cache has been archived or not.
    #
    # @return [Boolean] Has cache been archived?
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    def archived?
      @is_archived ||= begin
        raise NotFetchedError unless fetched?
        !!(@data =~ /<li>This cache has been archived/)
      end
    end

    # Whether the cache is only viewable to Premium Member only.
    #
    # @return [Boolean] Is cache PM-only?
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    def pmonly?
      @is_pmonly ||= begin
        raise NotFetchedError unless fetched?
        !!(@data =~ /<p class="Warning">Sorry, the owner of this listing has made it viewable to Premium Members only\./)
      end
    end

    # Returns an array of logs for this cache.  A log is an instance of
    # {Geocaching::Log}.
    #
    # @return [Geocaching::LogsArray<Geocaching::Log>] Array of logs
    # @raise [Geocaching::NotFetchedError] Need to call {#fetch} first
    # @raise [Geocaching::ExtractError] Could not extract logs from website
    def logs
      @logs ||= begin
        raise NotFetchedError unless fetched?

        logs = LogsArray.new
        elements = @doc.search("table.Table.LogsTable > tr > td > strong")

        if elements.size == 0
          raise ExtractError, "Could not extract logs from website"
        end

        elements.each do |node|
          img = node.search("img")
          a = node.search("a")

          title = img[0]["title"] if img.size == 1 and img[0]["title"]
          guid = $1 if a.size == 1 and a[0]["href"] and a[0]["href"] =~ /guid=([a-f0-9-]{36})/

          logs << Log.new(:guid => guid, :title => title, :cache => self)
        end

        logs
      end
    end

  private

    def path
      "/seek/cache_details.aspx?log=y&" + (@code ? "wp=#{@code}" : "guid=#{@guid}")
    end
  end
end