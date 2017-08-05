class Cookbook < ApplicationRecord

  has_many :users
  has_many :recipes
  has_many :tags

end
