class Admin::LeaguesController < Admin::AdminController
  before_action :set_league, only: [:show, :edit, :update, :destroy]
  
  def index
    @leagues = League.includes(:country).all.order(:name)
  end
  
  def show
  end
  
  def new
    @league = League.new
  end
  
  def create
    @league = League.new(league_params)
    
    if @league.save
      redirect_to admin_league_path(@league), notice: 'League was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @league.update(league_params)
      redirect_to admin_league_path(@league), notice: 'League was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @league.destroy
    redirect_to admin_leagues_path, notice: 'League was successfully deleted.'
  end
  
  private
  
  def set_league
    @league = League.find(params[:id])
  end
  
  def league_params
    params.require(:league).permit(:name, :country_id)
  end
end