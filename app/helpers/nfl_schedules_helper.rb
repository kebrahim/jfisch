module NflSchedulesHelper

  # displays a table of the specified nfl games
  def week_display_table(games)
    week_html = "<table class='" + ApplicationHelper::TABLE_CLASS + "'>
                   <thead><tr>
                     <th>Date</th>
                     <th colspan=2>Home Team</th>
                     <th colspan=2>Away Team</th>
                   </tr></thead>"
    games.each { |game|
      week_html << "<tr>
                      <td>" + game.start_time.time.localtime.strftime("%a %m/%d/%y %l%P") + "</td>
                      <td>" + game.home_nfl_team.abbreviation + "</td>
                      <td>" + game.home_score.to_s + "</td>
                      <td>" + game.away_nfl_team.abbreviation + "</td>
                      <td>" + game.away_score.to_s + "</td>
                    </tr>"
    }
    week_html << "</table>"
    return week_html.html_safe
  end
end
