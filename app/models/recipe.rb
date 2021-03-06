class Recipe < ApplicationRecord

  belongs_to :cookbook
  belongs_to :created_by, class_name: "User"
  belongs_to :photo, optional: true
  has_many :ratings
  has_and_belongs_to_many :menu_plans

  after_save :update_search_vector

  validates :name, presence: true, length: {minimum: 5}
  validates :ingredients, presence: true
  validates :created_by, presence: true
  validates :cookbook, presence: true

  def yumminess(user)
    ratings.where(user_id: user.id).pluck(:value).avg
  end

  def tags=(value)
    super Array(value).reject(&:blank?).map(&:downcase).uniq
  end

  def rating_for(user, name=user.name)
    ratings.where(user_id: user.id, name: name.chomp).pluck(:value)[0]
  end

  def self.search(query_string)
    config = PgSearch::Configuration.new({against: "plain_text"}, self)
    normalizer = PgSearch::Normalizer.new(config)
    options = { dictionary: "english", tsvector_column: "search_vector" }
    query = PgSearch::Features::TSearch.new(query_string, options, config.columns, self, normalizer)
    where(query.conditions)
  end

  def self.reindex!
    update_all <<-SQL
      search_vector = setweight(to_tsvector('english', name), 'A') ||
                      setweight(to_tsvector('english', ingredients), 'A') ||
                      setweight(to_tsvector('english', array_to_string(tags, ', ')), 'A') ||
                      setweight(to_tsvector('english', instructions), 'B')
    SQL
  end

  def self.most_popular_first
    order("coalesce((select avg(value) from ratings where recipe_id=recipes.id), 3) desc")
  end

  def tags=(tags)
    super Array(tags)
      .map { |tag| normalize_tag(tag) }
      .uniq
      .sort
  end

protected

  def normalize_tag(tag)
    tag.strip.downcase.gsub(/[^a-z0-9]/, "-").gsub(/\-{2,}/, "-")
  end

  def search_vector_should_change?
    (changed & %w{tags name ingredients instructions}).any?
  end

  def update_search_vector
    self.class.where(id: id).reindex!
  end

end
