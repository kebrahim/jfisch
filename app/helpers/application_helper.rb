module ApplicationHelper

  TABLE_CLASS = 'table table-striped table-bordered table-condensed center dashboardtable
                 vertmiddle'
  TABLE_STRIPED_CLASS = 'table table-dash-striped table-bordered table-condensed center
                 dashboardtable vertmiddle'

  # Shows the specified notice as an alert and displays it as an error, if the notice string starts
  # with "Error"
  def show_notice_as_alert(notice)
    return show_notice_as_alert_with_class_string(notice, nil)
  end

  # Shows the specified notice as an alert and displays it as an error, if the notice string starts
  # with "Error", including the specified class string.
  def show_notice_as_alert_with_class_string(notice, class_string)
    noticeHTML = ""
    if !notice.nil? && !notice.empty?
      if notice.starts_with?("Error:")
        noticeHTML << "<div class='alert alert-error alert-center"
      else
        noticeHTML << "<div class='alert alert-success alert-center"
      end
      if !class_string.nil? && !class_string.empty?
        noticeHTML << " " + class_string
      end
      noticeHTML << "'><button type='button' class='close' data-dismiss='alert'>&times;</button>" +
                    "<strong>" + notice + "</strong></div>"
    end
    return noticeHTML.html_safe
  end

  # shows the specified list of errors as an error alert
  def show_errors_as_alert(errors)
    return show_errors_as_alert_with_class_string(errors, nil)
  end

  # shows the specified list of errors as an error alert, with the additional classes
  def show_errors_as_alert_with_class_string(errors, class_string)
    errors_html = "<div class='alert alert-error alert-center"
    if !class_string.nil? && !class_string.empty?
      errors_html << " " + class_string
    end
    errors_html << "'><button type='button' class='close' data-dismiss='alert'>&times;</button>" +
                    "<strong>Errors occurred: "
    errors.each {
      errors_html << errors.join("; ")
    }
    errors_html << "</strong></div>"
    return errors_html.html_safe
  end

  # returns a select tag, allowing user to choose from a list of weeks, from 1 to the specified
  # current week, marking the specified selected week as selected
  def display_week_chooser(current_week, selected_week)
    week_chooser_html = "<label>Choose week:</label>&nbsp&nbsp
                         <select class='input-large' id='week_chooser'>"
    1.upto(current_week) { |week|
      week_chooser_html << "<option value=" + week.to_s
      week_chooser_html << " selected" if week == selected_week
      week_chooser_html << ">Week " + week.to_s + "</option>"
    }
    week_chooser_html << "</select>"
    return week_chooser_html.html_safe
  end

  # returns a link for a column header, which sorts by the specified column
  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = (column == sort_column) ? "current #{sort_direction}" : nil
    direction = (column == sort_column && sort_direction == "asc") ? "desc" : "asc"
    link_to title, {:sort => column, :direction => direction}, {:class => css_class}
  end
end
