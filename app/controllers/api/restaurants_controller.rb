class Api::RestaurantsController < ApplicationController
	before_action :ensure_logged_in, only: :create

	def show
		@restaurant = Restaurant.with_total.includes(:city, :rewards, :user).find(params[:id])
		if !@restaurant.published && !params[:edit]
			render text: "This restaurant is not public yet", status: 400
		elsif params[:edit] && current_user.id != @restaurant.user_id
			render text: "This restaurant is not your restaurant", status: 401
		end
	end

	def update
		@restaurant = Restaurant.find(params[:id])
		if logged_in_as?(@restaurant.user_id)
			@restaurant.update(restaurant_params)
			render :create
		else
			render text: "You must be logged in as owner to edit", status: 401
		end
	end

  def create
    @restaurant = Restaurant.new(restaurant_params)
    @restaurant.featured = false
    @restaurant.published = false
		@restaurant.city_id = @restaurant.city_id.to_i
    @restaurant.user_id = current_user.id
    @restaurant.save
  end

	def index

		if params[:cuisine_id] && params[:featured]
			@restaurants = Restaurant.includes(:city, :user).where(featured: true).where(published: true).where(cuisine_id: params[:cuisine_id]).order(title: :asc).page(1).per(params[:per])
			if @restaurants
				render :search_result
			else
				render text: "nothing here"
			end
		elsif params[:str]
			str = params[:str]
			str = str.split.map(&:capitalize).join(' ')
			@restaurants = Restaurant.includes(:city, :user).with_total.where("title LIKE ?", "%#{str}%").where(published: true).where("expiration > NOW()").limit(3).order(title: :asc)
		elsif params[:cuisine_id]
			per = params[:per] || 9
			@restaurants = Restaurant.includes(:city, :user).where(cuisine_id: params[:cuisine_id]).where(published: true).where("expiration > NOW()").order(title: :asc).page(1).per(per)

			render :search_result
		elsif params[:featured]
			@restaurants = Restaurant.includes(:city, :user).with_total.where(featured: true).where(published: true).where("expiration > NOW()").order(title: :asc)
			@restaurant = @restaurants.shuffle.first;
			render :show
		else
			@restaurants = Restaurant.includes(:city, :user).with_total.where(published: true).order(title: :asc)
			@restaurant = @restaurants.shuffle.first;
			render :show
		end
	end

  private

  def restaurant_params
    params.require(:restaurant).permit(
      :cuisine_id,
      :title,
      :city_id,
      :blurb,
      :description,
      :target,
      :expiration,
      :published,
			:image_url,
			:image
    )
  end

end
