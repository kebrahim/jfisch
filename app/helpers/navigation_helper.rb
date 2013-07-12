# Navigation bar helper
module NavigationHelper
  DASHBOARD_BUTTON = "DASHBOARD_BUTTON"
  MY_ENTRIES_BUTTON = "MY_ENTRIES_BUTTON"
  
  # Game buttons
  SURVIVOR_GAME_BUTTON = "SURVIVOR_GAME_BUTTON"
  ANTI_GAME_BUTTON = "ANTI_GAME_BUTTON"
  HIGH_ROLLER_GAME_BUTTON = "HIGH_ROLLER_GAME_BUTTON"

  # Admin buttons
  ADMIN_NFL_TEAMS_BUTTON = "ADMIN_NFL_TEAMS_BUTTON"
  ADMIN_NFL_SCHEDULE_BUTTON = "ADMIN_NFL_SCHEDULE_BUTTON"
  ADMIN_SURVIVOR_ENTRIES_BUTTON = "ADMIN_SURVIVOR_ENTRIES_BUTTON"

  # User buttons
  EDIT_PROFILE_BUTTON = "EDIT_PROFILE_BUTTON"

  def navigationBar(selected_button)
    navbar = "<div class='navbar'><div class='navbar-inner'>"
    if current_user
      navbar <<
        "<div class='brand'>J-Fisch Survivor</div>
         <ul class='nav'>" <<
         vertical_divider <<
         button_link(DASHBOARD_BUTTON, "Dashboard", "/dashboard", selected_button) <<
         # TODO only show my entries before season begins
         button_link(MY_ENTRIES_BUTTON, "My Entries", "/my_entries", selected_button) <<
         vertical_divider <<
         drop_down("Survivor Games", selected_button, 
             [{ btn: SURVIVOR_GAME_BUTTON, txt: "Survivor", lnk: "/survivor" },
              { btn: ANTI_GAME_BUTTON, txt: "Anti-Survivor", lnk: "/anti_survivor" },
              { btn: HIGH_ROLLER_GAME_BUTTON, txt: "High Roller", lnk: "/high_roller" }]) <<
         # TODO only show Admin dropdown for admin users
         drop_down("Admin", selected_button,
             [{ btn: ADMIN_NFL_TEAMS_BUTTON, txt: "NFL Teams", lnk: "/nfl_teams" },
              { btn: ADMIN_NFL_SCHEDULE_BUTTON, txt: "NFL Schedule", lnk: "/nfl_schedule" },
              { btn: ADMIN_SURVIVOR_ENTRIES_BUTTON, txt: "All Entries", lnk: "/all_entries" }]) <<
        "</ul>" <<
        "<ul class='nav pull-right'>" <<
         vertical_divider <<
         drop_down("Hi " + current_user.first_name + "!", selected_button,
             [{ btn: EDIT_PROFILE_BUTTON, txt: "Edit Profile", lnk: "/profile", icon: "edit" },
              { type: "divider" },
              { txt: "Sign out", lnk: "/logout", icon: "eject" }]) <<
        "</ul>"
    else
      navbar << "<div class='brand brandctr'>J-Fisch Survivor</div>"
    end
    navbar << "</div></div>"
    return navbar.html_safe
  end

  def drop_down(dropdown_text, selected_button, button_maps)
    drop_down_html = "<li class='dropdown"
    # if selected_button in list of child buttons, then add "active" class
    if button_maps.map do |button_map| button_map[:btn] end.include?(selected_button)
      drop_down_html << " active"
    end
    drop_down_html <<
      "'>
       <a href='#' class='dropdown-toggle profiledropdown' data-toggle='dropdown'>
           " + dropdown_text + "&nbsp<b class='caret'></b>
       </a>
       <ul class='dropdown-menu'>"
    # construct child buttons
    button_maps.each do |button_map|
      if button_map[:type] == "divider"
        drop_down_html << horizontal_divider
      else
        drop_down_html << button_link(button_map[:btn], button_map[:txt],
                                      button_map[:lnk], selected_button, button_map[:icon])
      end
    end
    drop_down_html << "  </ul>
                       </li>"
    return drop_down_html
  end

  def button_link(navigation_button, button_text, link_text, selected_button, icon = nil)
    button_html = "<li"
    if (selected_button == navigation_button)
      button_html << " class='active'"
    end
    button_html << "><a href='" + link_text + "'>"
    if !icon.nil?
      button_html << "<i class='icon-" + icon + "'></i>&nbsp&nbsp"
    end
    button_html << button_text + "</a></li>"
    return button_html
  end

  def horizontal_divider
    return "<li class='divider'></li>"
  end

  def vertical_divider
    return "<li class='divider-vertical'></li>"
  end
end