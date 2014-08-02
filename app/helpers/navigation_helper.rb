# Navigation bar helper
module NavigationHelper
  DASHBOARD_BUTTON = "DASHBOARD_BUTTON"
  MY_ENTRIES_BUTTON = "MY_ENTRIES_BUTTON"
  
  # Game buttons
  SURVIVOR_GAME_BUTTON = "SURVIVOR_GAME_BUTTON"
  ANTI_GAME_BUTTON = "ANTI_GAME_BUTTON"
  HIGH_ROLLER_GAME_BUTTON = "HIGH_ROLLER_GAME_BUTTON"
  SECOND_CHANCE_GAME_BUTTON = "SECOND_CHANCE_GAME_BUTTON"

  # Weekly breakdown buttons
  SURVIVOR_WEEKLY_BUTTON = "SURVIVOR_WEEKLY_BUTTON"
  ANTI_WEEKLY_BUTTON = "ANTI_WEEKLY_BUTTON"
  HIGH_ROLLER_WEEKLY_BUTTON = "HIGH_ROLLER_WEEKLY_BUTTON"
  SECOND_CHANCE_WEEKLY_BUTTON = "SECOND_CHANCE_WEEKLY_BUTTON"

  # Rules buttons
  SURVIVOR_RULES_BUTTON = "SURVIVOR_RULES_BUTTON"
  ANTI_RULES_BUTTON = "ANTI_RULES_BUTTON"
  HIGH_ROLLER_RULES_BUTTON = "HIGH_ROLLER_RULES_BUTTON"
  SECOND_CHANCE_RULES_BUTTON = "SECOND_CHANCE_RULES_BUTTON"

  # Admin buttons
  ADMIN_USERS_BUTTON = "ADMIN_USERS_BUTTON"
  ADMIN_ENTRIES_BUTTON = "ADMIN_ENTRIES_BUTTON"
  ADMIN_ALL_PICKS_BUTTON = "ADMIN_ALL_PICKS_BUTTON"
  ADMIN_NFL_SCHEDULE_BUTTON = "ADMIN_NFL_SCHEDULE_BUTTON"
  ADMIN_KILL_ENTRIES_BUTTON = "ADMIN_KILL_ENTRIES_BUTTON"

  # Super-admin buttons
  ADMIN_NFL_TEAMS_BUTTON = "ADMIN_NFL_TEAMS_BUTTON"
  ADMIN_SCORING_WEEKS_BUTTON = "ADMIN_SCORING_WEEKS_BUTTON"

  # User buttons
  EDIT_PROFILE_BUTTON = "EDIT_PROFILE_BUTTON"

  GAME_BUTTON_MAP = { survivor: SURVIVOR_GAME_BUTTON,
                      anti_survivor: ANTI_GAME_BUTTON, 
                      high_roller: HIGH_ROLLER_GAME_BUTTON,
                      second_chance: SECOND_CHANCE_GAME_BUTTON
                    }
  WEEKLY_BUTTON_MAP = { survivor: SURVIVOR_WEEKLY_BUTTON,
                        anti_survivor: ANTI_WEEKLY_BUTTON, 
                        high_roller: HIGH_ROLLER_WEEKLY_BUTTON,
                        second_chance: SECOND_CHANCE_WEEKLY_BUTTON
                      }
  RULES_BUTTON_MAP = { survivor: SURVIVOR_RULES_BUTTON,
                       anti_survivor: ANTI_RULES_BUTTON, 
                       high_roller: HIGH_ROLLER_RULES_BUTTON,
                       second_chance: SECOND_CHANCE_RULES_BUTTON
                     }

  def navigationBar(selected_button)
    navbar = "<div class='navbar'><div class='navbar-inner'>"
    if current_user
      navbar <<
        "<div class='brand'>Fisch Madness Survivor</div>
         <ul class='nav'>" <<
         vertical_divider <<
         button_link(DASHBOARD_BUTTON, "Dashboard", "/dashboard", selected_button) <<
         button_link(MY_ENTRIES_BUTTON, "My Entries", "/my_entries", selected_button) <<
         vertical_divider <<
         game_dropdown(selected_button)

      # only show Admin dropdown for admin users
      if current_user.is_admin
        admin_buttons =
            [
             { btn: ADMIN_USERS_BUTTON, txt: "Users", lnk: "/users" },
             { btn: ADMIN_ENTRIES_BUTTON, txt: "Entries", lnk: "/entries" },
             { btn: ADMIN_ALL_PICKS_BUTTON, txt: "All Picks", lnk: "/picks" },
             { type: "divider" },
             { btn: ADMIN_NFL_SCHEDULE_BUTTON, txt: "NFL Schedule", lnk: "/nfl_schedule" },
             { btn: ADMIN_KILL_ENTRIES_BUTTON, txt: "Kill Entries", lnk: "/kill_entries" },
            ]
        # only show super-admin options for super-admin users
        if current_user.is_super_admin
          admin_buttons <<
             { type: "divider" } <<
             { btn: ADMIN_NFL_TEAMS_BUTTON, txt: "NFL Teams", lnk: "/nfl_teams" } <<
             { btn: ADMIN_SCORING_WEEKS_BUTTON, txt: "Scoring Weeks", lnk: "/weeks" }
        end
        navbar << drop_down("Admin", selected_button, admin_buttons)
      end

      navbar <<
        "</ul>" <<
        "<ul class='nav pull-right'>" <<
         vertical_divider <<
         drop_down("Hi " + current_user.first_name + "!", selected_button,
             [{ btn: EDIT_PROFILE_BUTTON, txt: "Edit Profile", lnk: "/profile", icon: "edit" },
              { type: "divider" },
              { txt: "Sign out", lnk: "/logout", icon: "eject" }]) <<
        "</ul>"
    else
      navbar << "<div class='brand brandctr'>Fisch Madness Survivor</div>"
    end
    navbar << "</div></div>"
    return navbar.html_safe
  end

  def game_dropdown(selected_button)
    game_buttons = []
    SurvivorEntry::GAME_TYPE_ARRAY.each {|game_type|
      # hide second chance game from blacklisted user
      if (game_type == :second_chance &&
          (current_user.is_blacklisted || current_week < SurvivorEntry::SECOND_CHANCE_OPEN_WEEK))
        next
      end

      submenu_buttons = [
        { btn: GAME_BUTTON_MAP[game_type], txt: "Entry Breakdown", lnk: "/" + game_type.to_s },
        { btn: WEEKLY_BUTTON_MAP[game_type], txt: "Weekly Breakdown",
          lnk: "/" + game_type.to_s + "/week" },
        { btn: RULES_BUTTON_MAP[game_type], txt: "Rules", lnk: "/" + game_type.to_s + "/rules" }
      ]
      game_buttons << { btn: GAME_BUTTON_MAP[game_type],
                        txt: SurvivorEntry.game_type_title(game_type),
                        lnk: "#",
                        sub: submenu_buttons
                      }
    }
    return drop_down("Survivor Games", selected_button, game_buttons)
  end

  def get_buttons(button_maps)
    buttons = []
    button_maps.each { |button_map|
      buttons << button_map[:btn]
      if button_map[:sub]
        buttons.push(*get_buttons(button_map[:sub]))
      end
    }
    return buttons
  end

  def drop_down(dropdown_text, selected_button, button_maps)
    drop_down_html = "<li class='dropdown"
    # if selected_button in list of child buttons, then add "active" class
    if get_buttons(button_maps).include?(selected_button)
      drop_down_html << " active"
    end
    drop_down_html <<
      "'>
         <a href='#' class='dropdown-toggle profiledropdown' data-toggle='dropdown'>
           " + dropdown_text + "&nbsp<b class='caret'></b>
         </a>" <<
         drop_down_list(selected_button, button_maps) <<
       "</li>"
    return drop_down_html
  end

  def drop_down_list(selected_button, button_maps)
    list_html = "<ul class='dropdown-menu'>"
    # construct child buttons
    button_maps.each do |button_map|
      if button_map[:type] == "divider"
        list_html << horizontal_divider
      else
        list_html << button_link(button_map[:btn], button_map[:txt],
                                      button_map[:lnk], selected_button, button_map[:icon],
                                      button_map[:sub])
      end
    end
    list_html << "</ul>"
  end

  def button_link(navigation_button, button_text, link_text, selected_button, icon = nil,
                  submenu_buttons = nil)
    button_html = "<li class='"
    if (selected_button == navigation_button) ||
       (submenu_buttons && get_buttons(submenu_buttons).include?(selected_button))
      button_html << " active "
    end
    if submenu_buttons
      button_html << " dropdown-submenu "
    end
    button_html << "'><a href='" + link_text + "'>"
    if icon
      button_html << "<i class='icon-" + icon + "'></i>&nbsp&nbsp"
    end
    button_html << button_text + "</a>"

    if submenu_buttons
      button_html << drop_down_list(selected_button, submenu_buttons)
    end
    button_html << "</li>"
    return button_html
  end

  def horizontal_divider
    return "<li class='divider'></li>"
  end

  def vertical_divider
    return "<li class='divider-vertical'></li>"
  end
end