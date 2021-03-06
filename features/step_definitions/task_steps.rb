Given /^there is a task called "([^\"]*)"$/ do |name|
  Task.find_by_name(name) || Factory(:task, :name => name)
end

Given /^I have a task called "([^\"]*)"$/ do |name|
  task_list = @task_list || Factory(:task_list)
  project = @current_project || Factory(:project)
  @task = project.create_task(@current_user, task_list, {:name => name})
end

Given /^I have a task called "([^"]*)" with a comment including upload "([^"]*)"$/ do |task_name, file_name|

  Given %(I have a task called "#{task_name}")
  @comment = @task.comments.create :body => "Something to say"

  path = File.join(Rails.root, "spec/fixtures/#{file_name}")
  if File.exists?(path)
    @upload = Factory.create(:upload, {
      :asset => open(path),
      :asset_file_name => file_name,
      :asset_file_size => nil,
      :asset_content_type => nil,
      :project => @current_project,
      :comment => @comment
     })

  else
    Factory.create(:upload, :asset_file_name => file_name, :project => @current_project, :comment => @comment)
  end

end

## FIXME: it's better for 'givens' to set tasks up directly in the db:

Given /^the following tasks? with associations exists?:?$/ do |table|
  table.hashes.each do |hash|
    Factory(:task,
      :name => hash[:name],
      :task_list => TaskList.find_by_name(hash[:task_list]),
      :project => Project.find_by_name(hash[:project])
    )
  end
end

Given /^the following tasks? with hours exists?:?$/ do |table|
  table.hashes.each do |hash|
    Factory(:task,
      :name => hash[:name],
      :task_list => TaskList.find_by_name(hash[:task_list]),
      :project => Project.find_by_name(hash[:project]),
      :user => @current_user
      ).comments.create :body => hash[:comment], :human_hours => hash[:hours]
  end
end

Given /^the (p[a-z]+ )?task called "([^\"]*)" belongs to the task list called "([^\"]*)"$/ do |priv_type, task_name, task_list_name|
  priv_type = (priv_type||'').strip == 'private'
  Given %(there is a task called "#{task_name}")
  Given %(there is a task list called "#{task_list_name}")
  task_list = TaskList.find_by_name(task_list_name)
  task = Task.find_by_name(task_name)
  task.update_attribute(:task_list, task_list)
  task.update_attribute(:is_private, priv_type)
end

Given /^(@.+) created a (p[a-z]+ )?task named "([^\"]+)" in the task list called "([^\"]*)"$/ do |user_name, priv_type, task_name, task_list_name|
  is_private = (priv_type||'').strip == 'private'
  user = User.find_by_login(user_name.gsub('@',''))
  task_list = TaskList.find_by_name(task_list_name)
  task_list ||= @current_project.task_lists.create(:name => task_list_name, :user => user)
  Factory(:task, :user => user, :is_private => is_private, :name => task_name, :task_list => task_list, :project => task_list.project)
end


Given /^the task called "([^\"]*)" belongs to the project called "([^\"]*)"$/ do |task_name, project_name|
  Given %(there is a task called "#{task_name}")
  Given %(there is a project called "#{project_name}")
  project = Project.find_by_name(project_name)
  Task.find_by_name(task_name).update_attribute(:project, project)
end

Given /^the task called "([^\"]*)" is due today$/ do |name|
  Given %(there is a task called "#{name}")
  Task.find_by_name(name).update_attribute(:due_on, Date.today)
end

Given /^the task called "([^\"]*)" was due (\d+) days ago$/ do |name, days_ago|
  Given %(there is a task called "#{name}")
  Task.find_by_name(name).update_attribute(:due_on, Date.today - days_ago.to_i)
end

Given /^the task called "([^\"]*)" is due tomorrow$/ do |name|
  Given %(there is a task called "#{name}")
  Task.find_by_name(name).update_attribute(:due_on, Date.today + 1)
end

Given /^the task called "([^\"]*)" is due in (\d+) days?$/ do |name, in_days|
  Given %(there is a task called "#{name}")
  Task.find_by_name(name).update_attribute(:due_on, Date.today + in_days.to_i)
end

Given /^the task called "([^\"]*)" does not have a due date$/ do |name|
  Given %(there is a task called "#{name}")
  Task.find_by_name(name).update_attribute(:due_on, nil)
end

Given /^the task called "([^\"]*)" is assigned to me$/ do |name|
  Given %(there is a task called "#{name}")
  task = Task.find_by_name(name)
  task.project.add_user(@current_user)
  task.assign_to(@current_user)
end

Given /^the task called "([^\"]*)" is assigned to "([^\"]*)"$/ do |task_name, login|
  Given %(there is a task called "#{task_name}")
  task = Task.find_by_name(task_name)
  user = User.find_by_login(login)
  task.project.add_user(user)
  task.assign_to(user)
end

Given /^I have no tasks assigned to me$/ do
  @current_user.assigned_tasks.destroy_all
end

Given /^the task called "([^\"]*)" is (new|hold|open|resolved|rejected)(?:ed)?$/ do |name, status|
  Task.find_by_name(name).update_attribute(:status, Task::STATUSES[status.to_sym])
end

Then /^I should( not)? see the task called "([^\"]*)" in the "([^\"]*)" task list$/ do |negative, task_name, task_list_name|
  task_list = TaskList.find_by_name!(task_list_name)
  project = task_list.project
  Then %(I should#{negative} see "#{task_name}" within "#project_#{project.id}_task_list_#{task_list.id}_the_main_tasks")
end

Then /^I should see the following tasks:$/ do |table|
  table.hashes.each do |hash|
    Then %(I should see the task called "#{hash['task_name']}" in the "#{hash['task_list_name']}" task list)
  end
end

Then /^I should not see the following tasks:$/ do |table|
  table.hashes.each do |hash|
    Then %(I should not see the task called "#{hash['task_name']}" in the "#{hash['task_list_name']}" task list)
  end
end

Then /^I should see the task "([^\"]*)" before "([^\"]*)"$/ do |task1, task2|
  Task.find_by_name(task1).position.should < Task.find_by_name(task2).position
end

Then /^I fill the task comment box with "([^\"]*)"$/ do |text|
  Then %(I fill in "task[comments_attributes][0][body]" with "#{text}")
end

Then /^I click on the date selector$/ do
  find('.actions .localized_date').click
end

Then /^I select the month of "([^\"]*)" with the date picker$/ do |month|
  field = find("select[class='month']")
  field.select(month)
end

Then /^I select the year "([^\"]*)" with the date picker$/ do |year|
  field = page.find("select[class='year']")
  field.select(year)
end

Then /^I click on the (\w+) date selector$/ do |field|
  with_css_scope("#show_task_list div[id$=_#{field}_on]") do |node|
    node.find("span").click
  end
end

Then /^I select the (\w+) "([^"]*)" on the calendar$/ do |field, value|
  find(".#{field}").select(value)
end

Then /^I select the day "([^\"]*)" with the date picker$/ do |day|
  with_css_scope("div[class='calendar_date_select']") do |node|
    element = node.all(:xpath,"//*[.='#{day}']").detect {|e| e.tag_name == 'td' && !e['innerHTML'].include?('other')}
    element.try(:click)
  end
end

Then /^I should see "([^\"]*)"(?: and "([^\"]*)")? within the last comment body$/ do |text1, text2|
  comment = all("div.comments .body").last.text
  comment.should match(/#{text1}/)
  comment.should match(/#{text2}/)
end

Then /^I fill the name field with "([^"]*)"$/ do |name|
  Then %(I fill in "task_name" with "#{name}")
end

Then /^I should see "([^"]*)" within the task header$/ do |text|
  Then %(I should see "#{text}" within ".task_header h2")
end

Then /^I should see "([^"]*)" within the task actions$/ do |text|
  Then %(I should see "#{text}" within ".task .actions")
end

When /^(?:|I )select "([^\"]*)" in the "([^\"]*)" calendar?$/ do |number, calendar|
  with_css_scope("div[id$='_#{calender}_on']") do |node|
    find(:css,"table div[contains(#{number})]").click
  end
end

When /^(?:|I )select "([^\"]*)" in the calendar?$/ do |number|
  find(:css,"table div[contains(#{number})]").click
end

Then /^(?:|I )should see "([^\"]*)" status change?$/ do |text|
  if Capybara.current_driver == Capybara.javascript_driver
    assert page.has_xpath?(XPath::HTML.content(text), :visible => true)
  elsif page.respond_to? :should
    page.should have_content(text)
  else
    assert page.has_content?(text)
  end
end

Then /^I should see "([^\"]+)" in the task thread title$/ do |msg|
  link = false
  wait_until do
    link = find(".thread[data-class=task] .thread_title a")
  end
  comment = link.text
  comment.should match(/#{msg}/)
end

Given /^the task "([^\"]+)" is watched by (@.+)$/ do |name, users|
  task = Task.find_by_name(name)
  
  each_user(users) do |user|
    task.add_watcher(user)
  end
  
  task.save(:validate => false)
end

Given /^(?:he|she|I) tracks? (\d+) hours? on the task "([^"]*)" with the comment "([^"]*)"$/ do |hours, name, comment|
 task = Task.find_by_name(name)
 task.comments.create :body => comment, :human_hours => hours
end

Then /^(@.+) should( not)? be watching the task "([^\"]*)"$/ do |users, negate, name|
  conversation = Task.find_by_name(name)
  
  each_user(users) do |user|
    if negate.blank?
      user.should be_watching(conversation)
    else
      user.should_not be_watching(conversation)
    end
  end
end

