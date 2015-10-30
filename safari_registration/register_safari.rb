require 'mechanize'

class RegistrationChecker
  attr_reader :registration,  :notifier, :parser

  def initialize(registration:, parser: HtmlParser, notification: NotifySendNotifier.new)
    @registration = registration
    @notifier     = notification
    @parser       = parser
  end

  def register
    results = parser.new(content: registration).results
    notifier.display(results)
  end
end

class SubmitRegistration
  attr_reader :agent, :user

  def initialize(agent: Mechanize.new, user:)
    @agent = agent
    @user  = user
  end

  def submit
    register_url         = "http://techbus.safaribooksonline.com/_ajax_selfregisterpopup?__className=Register&__version=6.0.3"
    register_form_values = { "__SelfEmail": user.email, "__SelfFirstName": user.first_name,
                             "__SelfLastName": user.last_name, "__SelfSubmit": "Register",
                             "__formName": "RegistrationForm", "poratl": "techbus",
                             "uicode": "dodnavy" }

    registration = agent.post register_url, register_form_values
    valid_html(registration.content)
  end

  def valid_html(content)
    "<html><body>#{content}</body></html>"
  end
end

class NotifySendNotifier
  def display(message)
    `notify-send "Registration to Safari Online results" "#{message}" -t 10000 -i notification-message-email`
  end
end

class User
  attr_reader :first_name, :last_name, :email

  def initialize(name:, email:)
    @first_name, @last_name = name.split(' ')
    @email                  = email
  end
end

class HtmlParser
  attr_reader :parser, :content

  def initialize(parser: Nokogiri::HTML, content:)
    @parser  = parser
    @content = content
  end

  def results
    result_content = parser.parse(content).css('div.alrtBoxContent div p.p').first.content
    puts result_content

    if result_content =~ /^No more users can be added to this account/
      "Safari Online registration currently closed"
    else
      "Registration successful. Check work email"
    end
  end
end

name = ARGV[0]
email = ARGV[1]

if email =~ /@/
  user         = User.new(name: name, email: email)
  registration = SubmitRegistration.new(user: user).submit
  RegistrationChecker.new(registration: registration).register
else
  puts "USAGE: ruby safari_registartion.rb [full name] [email]"
end
