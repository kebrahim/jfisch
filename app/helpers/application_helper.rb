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
end
