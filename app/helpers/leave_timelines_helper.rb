module LeaveTimelinesHelper

  def timeline_zoom_link(timeline, in_or_out)
    case in_or_out
    when :in
      if timeline.zoom < 5
        link_to_content_update l(:text_zoom_in),
          params.merge(timeline.params.merge(:zoom => (timeline.zoom + 1))),
          :class => 'icon icon-zoom-in'
      else
        content_tag(:span, l(:text_zoom_in), :class => 'icon icon-zoom-in').html_safe
      end

    when :out
      if timeline.zoom > 1
        link_to_content_update l(:text_zoom_out),
          params.merge(timeline.params.merge(:zoom => (timeline.zoom - 1))),
          :class => 'icon icon-zoom-out'
      else
        content_tag(:span, l(:text_zoom_out), :class => 'icon icon-zoom-out').html_safe
      end
    end
  end

  def render_leave_tooltip(leave)
    s = ''.html_safe
    css_style = leave.css_style

    if leave.get_status == "accepted"
      s << "<div class=\"leave\" style=\"#{css_style}\">".html_safe
    else
      s << "<div class=\"strip\">".html_safe
    end

    s << '<strong><p>'.html_safe
    if leave.user_id.in?(@viewable_users.map(&:id))
      s << link_to("#{l(:leave_short)} \##{leave.id} - #{leave.issue.subject}", leave_request_path(leave), {:style => css_style}).html_safe
    else
      s << "#{l(:leave_short)} \##{leave.id} - #{leave.issue.subject}".html_safe
    end

    s << '</strong></p>'.html_safe

    s << '<table class="leave-table">'.html_safe
    s << '<th>'.html_safe
    s << avatar(leave.user, :size => "30").html_safe
    s << '</th><th><p>User: '.html_safe
    s << link_to("#{leave.user.name}", user_path(leave.user), {:style => css_style}).html_safe
    s << '</p>'.html_safe
    s << "<p>Region: #{leave.region}</p>".html_safe
    s << "<p>From: #{format_date(leave.from_date)}</p>".html_safe
    s << "<p>To: #{format_date(leave.to_date)}</p>".html_safe

    if leave.get_status != "accepted"
      s << "<p>Status: #{leave.get_status}</p>".html_safe
    end

    if leave.half_day?
      s << "<p><strong>#{leave.request_type.upcase} #{l(:leave_short)}</strong></p>".html_safe
    end

    s << '</th></table></div>'.html_safe
    return s.html_safe
  end

end