module ApplicationHelper

 def full_title(page_title = '')
  contain_title = "Ruby and Rails Tutorial"
  if	page_title.empty?
     contain_title
		else
		"#{page_title} | #{contain_title}"
  end
 end
end
