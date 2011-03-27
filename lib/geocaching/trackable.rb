# encoding: utf-8

module Geocaching
  # The {Trackable} class represents a log on geocaching.com.
  class Trackable
    # Creates a new instance and calls the {#fetch} method afterwards.
    # +:guid+ must be specified as an attribute.
    #
    # @param [Hash] attributes Hash of attributes
    # @return [Geocaching::Trackable]
    # @raise [ArgumentError] Unknown attribute provided
    # @raise [TypeError] Invalid attribute provided
    def self.fetch(attributes)
      log = new(attributes)
      log.fetch
      log
    end

    # Creates a new instance.  The following attributes may be specified
    # as parameters:
    #
    # * +:guid+ — The trackable’s Globally Unique Identifier
    #
    # @raise [ArgumentError] Trying to set an unknown attribute
    def initialize(attributes = {})
      @data, @doc, @guid, @cache = nil, nil, nil, nil

      attributes.each do |key, value|
        if [:guid, :title, :date, :cache, :user].include?(key)
          if key == :cache and not value.kind_of?(Geocaching::Cache)
            raise TypeError, "Attribute `cache' must be an instance of Geocaching::Cache"
          end

          if key == :date and not value.kind_of?(Time)
            raise TypeError, "Attribute `type' must be an instance of Time"
          end

          if key == :user and not value.kind_of?(User)
            raise TypeError, "Attribute `user' must be an instance of Geocaching::User"
          end

          instance_variable_set("@#{key}", value)
        else
          raise ArgumentError, "Trying to set unknown attribute `#{key}'"
        end
      end
    end

    # Fetches log information from geocaching.com.
    #
    # @return [void]
    # @raise [ArgumentError] GUID is not given
    def fetch
      raise ArgumentError, "No GUID given" unless @guid
      raise LoginError unless HTTP.loggedin?

      resp, @data = HTTP.get("/track/details.aspx?guid=#{@guid}")
      @doc = Nokogiri::HTML.parse(@data, nil, 'UTF-8')
    end

    # Returns whether log information have successfully been fetched
    # from geocaching.com.
    #
    # @return [Boolean] Have log information beed fetched?
    def fetched?
      @data and @doc
    end

    # Returns the log’s GUID.
    #
    # @return [String] GUID
    def guid
      @guid
    end
    
    # Returns the the code for the travel bug
    #
    # @return [String] ID
    def code
      @code ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("#ctl00_ContentBody_BugDetails_BugTBNum > strong")
    
        if elements.size > 0
          HTTP.unescape(elements.first.inner_html)
        else
          raise ParseError, "Could not extract code from website"
        end
      end
    end
    
    # Returns the the name of the travel bug
    #
    # @return [String] Name
    def name
      @name ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("#ctl00_ContentBody_lbHeading")
    
        if elements.size > 0
          HTTP.unescape(elements.first.inner_html)
        else
          raise ParseError, "Could not extract name from website"
        end
      end
    end
    
    # Returns the trackable’s owner.
    #
    # @return [Geocaching::User] Owner
    def owner
      @owner ||= begin
        raise NotFetchedError unless fetched?
        elements = @doc.search("a#ctl00_ContentBody_BugDetails_BugOwner[href*='/profile/?guid=']")

        if elements.size == 1 and elements.first["href"] =~ /guid=([a-f0-9-]{36})/
          @owner_display_name = HTTP.unescape(elements.first.content)
          User.new(:guid => $1)
        else
          raise ParseError, "Could not extract owner from website"
        end
      end
    end
    
    # Returns the displayed trackable owner name.
    #
    # @return [String] Displayed owner name
    def owner_display_name
      owner unless @owner_display_name
      @owner_display_name
    end
    
    # Returns the date the trackable was released at.
    #
    # @return [Time] Release date
    def released_at
      @hidden_at ||= begin
        raise NotFetchedError unless fetched?

        if @data =~ /<span id="ctl00_ContentBody_BugDetails_BugReleaseDate">.*, (\d{1,2}) (.*) (\d{4})<\/span>/
          Time.mktime($3, Date::MONTHNAMES.index($2), $1)
        else
          raise ParseError, "Could not extract hidden date from website"
        end
      end
    end
    
    # Returns the trackable’s origin name (State, Country).
    #
    # @return [String] Location name
    def origin
      @origin ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("span#ctl00_ContentBody_BugDetails_BugOrigin")
    
        if elements.size > 0
          HTTP.unescape(elements.first.inner_html)
        else
          raise ParseError, "Could not extract origin from website"
        end
      end
    end
    
    # Returns the trackable’s goal.
    #
    # @return [String] Goal
    def goal
      @goal ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("div.yui-g > p.NoSpacing")
    
        if elements.size > 0
          HTTP.unescape(elements.first.inner_html).strip
        else
          raise ParseError, "Could not extract goal from website"
        end
      end
    end
    
    # Returns the trackable’s about section.
    #
    # @return [String] About
    def about
      @about ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("div.yui-g > p.NoSpacing")
    
        if elements.size > 0
          HTTP.unescape(elements[1].inner_html).strip
        else
          raise ParseError, "Could not extract about section from website"
        end
      end
    end
    
    # Returns the trackable’s distance travelled.
    #
    # @return [Float] distance_travelled
    def distance_travelled
      @distance_travelled ||= begin
        raise NotFetchedError unless fetched?
    
        if @data =~ /<h3>\s*Tracking History \(([0-9.0-9]*)/
          $1.to_f
        else
          raise ParseError, "Could not extract distance travelled from website"
        end
      end
    end

    # Returns the cache or user that currently has this trackable.
    #
    # @return [Geocaching::Cache] Cache / [Geocaching::User] User 
    def last_spotted
      @last_spotted ||= begin
        raise NotFetchedError unless fetched?
    
        elements = @doc.search("a#ctl00_ContentBody_BugDetails_BugLocation")

        if elements.first["href"] =~ /cache_details.aspx\?guid=([a-f0-9-]{36})/
          Cache.new(:guid => $1)
        elsif elements.first["href"] =~ /\/profile\/\?guid=([a-f0-9-]{36})/
          User.new(:guid => $1)
        elsif elements.first["href"].nil?
          owner
        else
          raise ParseError, "Could not extract about section from website"
        end
      end
    end

    # Returns the trackable’s type.
    #
    # @return [Geocaching::TrackableType] Log type
    def type
      @type ||= title.downcase.gsub(' ', '_').to_sym
    end

  private

    # Returns the log’s title which is used internally to get the log type.
    #
    # @return [String] Log title
    def title
      @title ||= begin
        raise NotFetchedError unless fetched?
    
        imgs = @doc.search("#ctl00_ContentBody_BugTypeImage")
    
        unless imgs.size == 1 and imgs.first["alt"]
          raise ParseError, "Could not extract title from website"
        end
    
        imgs.first["alt"]
      end
    end

    # Returns an array of information that are provided on the website
    # in <meta> tags.
    #
    # @return [Hash] Log information
    def meta
      @meta ||= begin
        elements = @doc.search("meta").select { |e| e["name"] =~ /^og:/ }.flatten
        info = {}

        elements.each do |element|
          info[element["name"].gsub(/^og:/, "").to_sym] = element["content"]
        end

        info
      end
    end
  end
end
