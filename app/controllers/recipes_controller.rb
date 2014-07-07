class RecipesController < ApplicationController
  before_action :find_recipe, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!, only: [:edit, :new, :create, :update, :destroy]

  def index
    @recipes = Recipe.all
  end

  def show
  end

  def new
    @recipe = Recipe.new
    authorize! :create, @recipe
  end

  def edit
    authorize! :update, @recipe
  end

  def create
    @recipe = Recipe.new(recipe_params)
    authorize! :create, @recipe

    @recipe.created_by = current_user
    if @recipe.save
      redirect_to @recipe, notice: 'Recipe was successfully created.'
    else
      render :new
    end
  end

  def update
    authorize! :update, @recipe
    
    if @recipe.update(recipe_params)
      redirect_to @recipe, notice: 'Recipe was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @recipe.destroy
    redirect_to recipes_url, notice: 'Recipe was successfully destroyed.'
  end



private

  def find_recipe
    @recipe = Recipe.find(params[:id])
  end

  def recipe_params
    attributes = params
      .require(:recipe)
      .permit(:name, :ingredients, :instructions, :tags, :effort, :cost, :healthiness)
    attributes.merge(tags: attributes[:tags].to_s.split(","))
  end

end