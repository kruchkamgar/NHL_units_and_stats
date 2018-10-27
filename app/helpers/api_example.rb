module GoogleBooks

  require 'rest-client'
  require 'json'
  require 'pry'

  def get_json(url) # Accepts a URL for an API page and returns JSON data.
    response_string = RestClient.get(url)
    response_hash = JSON.parse(response_string)
  end

  def make_film_array(array_of_api_urls)
    # Accepts an array of API_URLs and
    # returns an array of JSON data
    array_of_api_urls.map do |film_url|
      get_json(film_url)
    end
  end

  def get_character_movies_from_api(character)
    # Returns an array of the JSON data
    # of each film the passed character was in.

    # People is an array of hashes of data about
    # all characters with available data
    people_hash = get_json('http://www.swapi.co/api/people/')

    api_urls = {}

    # Iterates over each character in Star Wars
    # If the passed character exists, it takes out
    # api urls for each film the character was in.
    people_hash["results"].each do |character_hash|
      # In the CLI we always downcase user input
      # so we must check against a downcased list as well.
      if character_hash["name"].downcase == character
        api_urls = character_hash["films"]
      end
    end

    # If no character equalling the user input has been
    # found we inform the user politely.
    if api_urls.empty?
      puts "Ironic. #{character.capitalize} was not in Star Wars."
      return []
    else
      # If the character HAS been found, we convert the
      # api urls into an array of hashes of movie data.
      make_film_array(api_urls)
    end

  end

  def print_movies(films_hash)
    # Iterates over the array of hashes
    # and puts the title of each film
    films_hash.each do |film|
      puts film["title"]
    end
  end

  def show_character_movies(character)
    films_array = get_character_movies_from_api(character)
    print_movies(films_array)
  end


end
