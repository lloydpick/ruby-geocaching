module Geocaching
  # The {LogArray} class is a subclass of +Array+ and is used to store all
  # logs that belong to a cache.  It implements the {#fetch_all} method to
  # fetch the information of all logs inside the array.
  class LogArray < Array
    # Calls {Geocaching::Log#fetch} for each log inside the array.
    #
    # @return [Boolean] Whether all logs could be fetched successfully
    def fetch_all
      each { |log| log.fetch }
      map { |log| log.fetched? }.all?
    end
  end
end