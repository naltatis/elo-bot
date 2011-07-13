require 'elo'
require 'json'
require 'net/http'
require 'pp'

class EloRatings
  def initialize
    @teams = {}
  end
  
  def process (matches)
    matches.each do |match|
      t1 = team match['id_team1']
      t2 = team match['id_team2']
      
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
    match['points_team1'].to_i - match['points_team2'].to_i
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

class Botliga
  def initialize(token)
    @http = Net::HTTP.new('botliga.de', 80)
    @token = token
  end
  
  def post(match_id, result)
    @http.post('/api/guess',"match_id=#{match_id}&result=#{result}&token=#{@token}")
  end
end


file = File.open("data/matches.json", "rb")
matches = JSON.parse(file.read)

liga = Botliga.new(ARGV[0])

r = EloRatings.new
r.process(matches) do |match, we|
  if match['league_saison'] == '2010'
    if we < 0.5
      result = '0:1'
    else
      result = '2:1'
    end
      
    pp liga.post(match['match_id'], result)
  end
end

puts 