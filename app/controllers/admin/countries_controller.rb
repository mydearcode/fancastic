class Admin::CountriesController < Admin::AdminController
  before_action :set_country, only: [:show, :edit, :update, :destroy]
  
  def index
    @countries = Country.all.order(:name)
  end
  
  def show
  end
  
  def new
    @country = Country.new
  end
  
  def create
    @country = Country.new(country_params)
    
    if @country.save
      redirect_to admin_country_path(@country), notice: 'Country was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @country.update(country_params)
      redirect_to admin_country_path(@country), notice: 'Country was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @country.destroy
    redirect_to admin_countries_path, notice: 'Country was successfully deleted.'
  end
  
  private
  
  def set_country
    @country = Country.find(params[:id])
  end
  
  def country_params
    params.require(:country).permit(:name, :code)
  end
end