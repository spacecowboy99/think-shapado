module QuestionsHelper
  def microblogging_message(question)
    message = "#{h(question.title)}"
    message += " "
    message +=  question_path(question, :only_path =>false)
    message
  end

  def share_url(question, service)
    url = ""
    case service
      when :identica
        url = "http://identi.ca/notice/new?status_textarea=#{microblogging_message(question)}"
      when :shapado
        url = "http://shapado.com?"
      when :twitter
        url = "http://twitter.com/?status=#{microblogging_message(question)}"
      when :facebook
        url = "http://www.facebook.com/sharer.php?u=#{microblogging_message(question)}&t=TEXTO"
      when :linkedin
<<<<<<< HEAD:app/helpers/questions_helper.rb
        url = "http://linkedin.com?"
      when :think
        url = "http://think.it?"
=======
        url = "http://linkedin.com/shareArticle?mini=true&url="+question_path(question, :only_path =>false)+"&title=#{h(question.title)}&summary=#{h(question.body)}&source=Shapado"
      when :think
        url = "http://beta.think.it:3000?"
>>>>>>> 4d59e5979dc30f7f8ca0c4378ea167c2e786f940:app/helpers/questions_helper.rb
    end
    url
  end
end
