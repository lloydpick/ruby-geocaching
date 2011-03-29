Ruby API for geocaching.com
===========================

This Ruby library provides an API for geocaching.com.


API Info
---

Login
-----
    https://api.groundspeak.com/mango/Services.asmx/OpenSessionEx?licenseKey=e0dc6788-c880-4d3c-8903-3e2230650281&userName=USERNAME&password=PASSWORD&deviceId=&language=en&version=4.2.2&checksum=&deviceType=&schemaName=SessionDataSet2.xsd

Trackables in Inventory
-----
    https://api.groundspeak.com/mango/Services.asmx/GetTrackableItemInventory?sessionToken=SESSION_TOKEN

Trackable Info
-----
    https://api.groundspeak.com/mango/Services.asmx/GetTravelBugByTrackingNumber?sessionToken=SESSION_TOKEN&TrackingNumber=TRACKING_NUMBER
    
Cache Info
-----
    https://api.groundspeak.com/mango/Services.asmx/GetCachesByCacheCode?sessionToken=SESSION_TOKEN&schemaName=CacheGPXDataSet.xsd&cacheCode=CACHE_CODE
    
Cache Attributes
-----
    https://api.groundspeak.com/mango/Services.asmx/GetAttributesByWptCode?sessionToken=SESSION_TOKEN&wptCode=CACHE_CODE&schemaName=AttributeSimpleDataSet.xsd

Cache Logs
-----
    https://api.groundspeak.com/mango/Services.asmx/GetCacheLogsByCacheCodePaged?sessionToken=SESSION_TOKEN&cacheCode=CACHE_CODE&startPos=0&endPos=9&cacheLogTypeNames=&

Trackables in Cache
-----
    https://api.groundspeak.com/mango/Services.asmx/GetTravelBugsByCacheCode?sessionToken=SESSION_TOKEN&cacheCode=CACHE_CODE

Waypoints for Cache
-----
    https://api.groundspeak.com/mango/Services.asmx/GetAdditionalWptsByWptCode?sessionToken=SESSION_TOKEN&wptCode=CACHE_CODE&schemaName=WaypointDataSet.xsd
    
Usage
-----

    require "geocaching"
    
    # Logging in is not always necessary, but some information are only
    # accessible when logged in.
    Geocaching::HTTP.login("username", "password")
    
    # Fetch the information for a cache by the cache’s GC code.  You can also
    # provide the cache’s GUID instead of the GC code.
    cache = Geocaching::Cache.fetch(:code => "...")
    
    # Print some cache information.
    puts "      Name: #{cache.name}"
    puts "Difficulty: #{cache.difficulty}"
    puts "     Owner: #{cache.owner.username}"
    
    # Print the number of logs.
    puts "      Logs: #{cache.logs.size}"
    
    # Print the number of users that didn’t find the cache.
    dnfs = cache.logs.select { |log| log.type == :dnf }.size
    puts "      DNFs: #{dnfs}"
    
    # Fetch the information for a log by its GUID.
    log = Geocaching::Log.fetch(:guid => "...")
    
    # Print some log information.
    puts "Username: #{log.user.name}"
    puts "   Words: #{log.message.split.size}"
    puts "   Cache: #{log.cache.name}"
    
    Geocaching::HTTP.logout

The whole library may raise the following exceptions:

* `Geocaching::TimeoutError` when a timeout is hit.
* `Geocaching::LoginError` when calling a method that requires being
  logged in and you’re not.
* `Geocaching::NotFetchedError` when accessing a method that requires the
  `fetch` method to be called first.
* `Geocaching::ExtractError` when information could not be extracted
  out of the website’s HTML code.  This mostly happens after Groundspeak
  changed their website.
* `Geocaching::HTTPError` when a HTTP request failed.

All exceptions are subclasses of `Geocaching::Error`.


Tests
-----

Tests are written using [RSpec](http://relishapp.com/rspec).
You need [Bundler](http://gembundler.com/) to run the tests.

    $ bundle update
    $ GC_USERNAME="username" GC_PASSWORD="password" bundle exec rake test

Additional environment variables you may specify are:

* `GC_TIMEOUT` — HTTP timeout in seconds
* `GC_CACHE_TYPES` — A space-separated list of cache types you want to test.
* `GC_LOG_TYPES` — A space-separated list of log types you want to test.
