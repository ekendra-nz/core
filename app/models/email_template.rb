# An email template which can be personalised for a given customer
class EmailTemplate

  # white-list of special keywords to be replaced
  KEYWORDS = %w(first_name last_name account_balance)

  # 2-array with left and right keyword delimiters
  DELIMITERS = %w({ })

  attr_reader :subject, :body
  attr_reader :errors

  def initialize(subject, body)
    @subject, @body = subject, body

    @errors = []
  end

  def valid?
    @errors << "Subject can't be blank" if subject.blank?
    @errors << "Body can't be blank" if body.blank?

    unless unknown_keywords.empty?
      @errors << "Unknown keywords found: #{unknown_keywords.join(', ')}"
    end

    @errors.empty?
  end

  def personalise customer
    raise @errors unless valid?

    replace_map = KEYWORDS.inject({}) do |hash, keyword|
      replace = customer.public_send(keyword)

      # NOTE: format money - will need to be less ad-hoc if we add new keywords
      replace = replace.format if replace.respond_to? :format

      hash.merge!(keyword => replace.to_s)
    end.freeze

    personalised = {}

    [:subject, :body].each do |attribute|
      attribute_value = public_send attribute

      replace_map.each do |key, value|
        attribute_value.gsub!(EmailTemplate.keyword_with_delimiters(key), value)
      end

      personalised[attribute] = attribute_value
    end

    EmailTemplate.new(personalised[:subject], personalised[:body]).freeze
  end

  def unknown_keywords
    regexp = /#{Regexp.escape(DELIMITERS.first)}(.*?)#{Regexp.escape(DELIMITERS.last)}/
    keywords = body.to_s.scan(regexp).map(&:first)
    keywords - KEYWORDS
  end

  def self.keyword_with_delimiters keyword
    "#{DELIMITERS.first}#{keyword}#{DELIMITERS.last}"
  end

  def self.keywords_with_delimiters
    KEYWORDS.map do |keyword|
      keyword_with_delimiters keyword
    end
  end
end
