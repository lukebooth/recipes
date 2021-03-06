class Cookbook < ApplicationRecord

  has_many :users
  has_many :recipes
  has_many :menu_plans
  belongs_to :current_menu_plan, class_name: "MenuPlan", required: false

  after_create :create_first_menu_plan!

private

  def create_first_menu_plan!
    self.current_menu_plan = menu_plans.create!(name: "My First Menu Plan")
    update_column :current_menu_plan_id, current_menu_plan.id
  end

end
