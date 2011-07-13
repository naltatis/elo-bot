require 'net/http'
require 'json'
require 'pp'

matches = []

http = Net::HTTP.new('openligadb-json.heroku.com',80)

(2006..2010).each do |year| 
  (1..34).each do |group| 
    query = "group_order_id=#{group}&league_saison=#{year}&league_shortcut=bl1"
    response = http.get("/api/matchdata_by_group_league_saison?#{query}")
    data = JSON.parse(response.body)
    matches = matches + data['matchdata']
  end
end

File.open('data/matches.json', 'w') do |f|
  f.write(matches.to_json)
end

puts matches.size