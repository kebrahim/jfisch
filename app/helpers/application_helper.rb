module ApplicationHelper

  # Shows the specified notice as an alert and displays it as an error, if the notice string starts
  # with "Error"
  # TODO take margin classes as params
  def show_notice_as_alert(notice)
    noticeHTML = ""
    if !notice.nil? && !notice.empty?
      if notice.starts_with?("Error:")
        noticeHTML << "<div class='alert alert-error alert-center'>"
      else
        noticeHTML << "<div class='alert alert-success alert-center'>"
      end
      noticeHTML << "<button type='button' class='close' data-dismiss='alert'>&times;</button>" +
                    "<strong>" + notice + "</strong></div>"
    end
    return noticeHTML.html_safe
  end
end
