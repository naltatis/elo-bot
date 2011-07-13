require 'elo'
require 'pp'

class Importer
  def run(from, to)
    matches = []
    (from..to).each do |year|
      puts year
      matches = matches + read(year)
    end
    puts "#{matches.size} games"
    matches
  end
  
  private

  def read(year)
    matches = []
    
    f = File.open("data/#{year}.txt", "r") 
    f.each_line do |line|
      entry = parse_line(line)
      matches << entry if entry
    end
    matches
  end
  
  def parse_line line
    if line.include? 'Spieltag'
      @group = line[3,3].strip
    else
      @date = line[6,10] unless line[6,10].strip.empty?
      @time = line[17,5] unless line[17,5].strip.empty?
      
      first, last = line.split ' - '

      entry = {:group => @group, :date => @date, :time => @time, :year => @year}
      result = last.match /(.*)\w*(\d):(\d)/
      entry[:team2] = result[1].strip
      entry[:points1] = result[2].strip.to_i
      entry[:points2] = result[3].strip.to_i
      entry[:team1] = first[-20,20].strip
    
      entry[:diff] = entry[:points1] - entry[:points2]
    
      entry[:tendency] = 'home' if entry[:diff] > 0
      entry[:tendency] = 'guest' if entry[:diff] < 0
      entry[:tendency] = 'draw' if entry[:diff] == 0
    end
    
    entry
  end
end


class Ratings
  def initialize
    @teams = {}
  end
  
  def process matches
    matches.each do |match|
      t1 = team match[:team1]
      t2 = team match[:team2]
      
      g = t1.versus(t2)
      
      dr = t1.rating - t2.rating + 100
      we = 1.0 / (10 ** (-1*dr/400.0) + 1)
      puts "#{we} #{match[:tendency]}"
      
      if match[:tendency] == 'home'
        g.winner = t1
      elsif match[:tendency] == 'guest'
        g.winner = t2
      else
        g.draw
      end
    end
    @teams.each { |k,v| puts "elo: #{v.rating}\tgames: #{v.games_played}\tteam: #{k}"}
  end
  
  private
  def team (name)
    @teams[name] ||= Elo::Player.new
  end
end



i = Importer.new
matches = i.run(2007, 2010)

r = Ratings.new
r.process matches
