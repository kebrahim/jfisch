module WeeksHelper

  # displays the team bets breakdown by week table
  def bets_by_week_table(team_map, team_to_results_map)
    week_table_html = "<table class='" + ApplicationHelper::TABLE_CLASS + "'>
                         <thead><tr>
                           <th>Team</th>
                           <th>Opponent</th>
                           <th>Result</th>
                           <th>Entry Count</th>
                         </tr></thead>"

    total_bet_count = 0
    eliminated_bet_count = 0
    team_to_results_map.sort_by {|k,v| v["count"]}.reverse.each { |team_id, results_map|
      # mark team row as correct/incorrect
      week_table_html << "<tr"
      if !results_map["is_correct"].nil?
        week_table_html << " class = '" +
                           (results_map["is_correct"] ? "green-row" : "red-row") + "'"
      end

      week_table_html << "><td>" + team_map[team_id].full_name + "</td>
		                   <td>" + team_map[results_map["oppo_id"]].full_name + "</td>
		                   <td>" + results_map["result"] + "</td>
		                   <td class='leftborderme'>" + results_map["count"].to_s + "</td>
		                  </tr>"
      total_bet_count += results_map["count"]
      if results_map["is_correct"] == false
        eliminated_bet_count += results_map["count"]
      end
    }

    # total entries placing bets for the week
    week_table_html << "<tr class='bold-row'>
                          <td colspan=3 class='topborderme'>Total Entries</td>
                          <td class='topborderme leftborderme'>" + total_bet_count.to_s + "</td>
                        </tr>"

    # eliminated entries during the week
    week_table_html << "<tr class='bold-row'>
                          <td colspan=3>Eliminated Entries</td>
                          <td class='leftborderme'>" + eliminated_bet_count.to_s + "</td>
                        </tr>"

    # remaining entries during the week
    week_table_html << "<tr class='bold-row'>
                          <td colspan=3>Remaining Entries</td>
                          <td class='leftborderme'>" + (total_bet_count - eliminated_bet_count).to_s + "</td>
                        </tr>"

    week_table_html << "</table>"
    return week_table_html.html_safe
  end
end
