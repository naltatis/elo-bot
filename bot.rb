require 'elo'
require 'json'
require 'date'
require 'net/http'
require 'pp'

class EloRatings
  def initialize
    @teams = {}
  end

  def process (matches)
    matches.each do |match|
      t1 = team match['hostId']
      t2 = team match['guestId']

      we = estimate(t1.rating, t2.rating)

      yield match, we

      calculate(t1, t2, match)
    end
  end

  private

  # see http://de.wikipedia.org/wiki/World_Football_Elo_Ratings
  def estimate (rating1, rating2)
    dr = rating1 - rating2 + 100
    we = 1.0 / (10 ** (-1*dr/400.0) + 1)
    we
  end

  def diff (match)
    match['hostGoals'].to_i - match['guestGoals'].to_i
  end

  def calculate (t1, t2, match)
    g = t1.versus(t2)
    if diff(match) > 0
      g.winner = t1
    elsif diff(match) < 0
      g.winner = t2
    else
      g.draw
    end
  end

  def team (id)
    @teams[id] ||= Elo::Player.new
  end
end

class Importer
  def initialize
    @http = Net::HTTP.new('botliga.de',80)
  end

  def import
    matches = []
    (2010..2013).each do |year|
      puts ">> /api/matches/#{year}"
      response = @http.get("/api/matches/#{year}")
      data = JSON.parse(response.body)
      matches = matches + data
    end
    matches
  end
end

class Botliga
  def initialize(token)
    @uri = URI('http://botliga.de/api/guess')
    #@uri = URI('http://localhost:3000/api/guess')
    @token = token
  end

  def post(match_id, result)
    Net::HTTP.post_form(@uri, :match_id => match_id, :result => result, :token => @token)
  end
end

importer = Importer.new
matches = importer.import

liga = Botliga.new(ARGV[0])

r = EloRatings.new
r.process(matches) do |match, we|
  if DateTime.parse(match["date"]) > DateTime.now
    if we < 0.35
      result = '1:3'
    elsif we < 0.4
      result = '1:2'
    elsif we < 0.45
      result = '0:1'
    elsif we < 0.5
      result = '0:0'
    elsif we < 0.55
      result = '1:1'
    elsif we < 0.6
      result = '1:0'
    elsif we < 0.65
      result = '2:1'
    else
      result = '2:0'
    end
    puts "#{result} - #{match['id']} - #{match['hostName']} vs. #{match['guestName']}"
    pp liga.post(match['id'], result)
  end
end