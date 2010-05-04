atom_feed do |feed|
  title = "#{AppConfig.domain} - #{@user.login}'s Questions"
  feed.title(title)
  unless @questions.empty?
    feed.updated(@questions.first.updated_at)
  end

  for question in @questions
    next if question.updated_at.blank?
    feed.entry(question, :url => question_url("all", question), :id =>"tag:#{question.id}") do |entry|
      entry.title(question.title)
      entry.content(markdown(question.body), :type => 'html')
      entry.updated(question.updated_at.strftime("%Y-%m-%dT%H:%M:%SZ"))
      entry.author do |author|
        author.name(question.user.login)
      end
    end
  end
end
