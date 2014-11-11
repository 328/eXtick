class TicketsController < ApplicationController 
  before_action(:set_ticket, only: [:show, :edit, :update, :destroy])
  before_action(:set_user_id, only: [:edit, :update])
  before_action(:set_user, only: [:edit, :new, :update, :create])

  
  # GET /tickets
  # GET /tickets.json
  def index
    @tickets = Ticket.order("created_at DESC").page(params[:page]).per(Ticket::PagenatePer)
    @ticket = Ticket.new
  end

  # GET /tickets/1
  # GET /tickets/1.json
  def show
  end

  # GET /tickets/new
  def new
    # this user did not login.
    if @user.blank?
      redirect_to(action: :index)
    else
      @ticket = Ticket.new
    end
  end
  
  # GET /tickets/1/edit
  def edit
    @tags = @ticket.tags
  end
  
  # POST /tickets
  # POST /tickets.json
  def create
    param = params[:params]
    @ticket = Ticket.create(ticket_params)
    
    if @ticket.valid?
      if param[:categories]
        param[:categories].each do |id|
          @ticket.categories << Category.find_by(id: id)
        end
      end
      if param[:tags]
        param[:tags].split(",").uniq.each do |name|
          @ticket.tags <<  Tag.find_or_create_by(name: name.strip)
        end
      end
      redirect_to(@ticket, notice: t('success_message'))
    else
      redirect_to(action: :new)
    end
    
  end

  # PATCH/PUT /tickets/1
  # PATCH/PUT /tickets/1.json
  def update
    param = params[:params]

    TicketCategory.transaction do
      TicketCategory.delete_all(ticket_id: @ticket.id)
      if param[:categories]
        param[:categories].each do |id|
          @ticket.categories << Category.find_by(id: id)
        end
      end
    end
    
    TicketTag.transaction do
      TicketTag.delete_all(ticket_id: @ticket.id)
      param[:tags].split(",").uniq.each do |name|
        @ticket.tags <<  Tag.find_or_create_by(name: name.strip)
      end
    end
    
    if @ticket.update(ticket_params)
      redirect_to(@ticket, notice: 'Ticket was successfully updated.')
    else
      redirect_to(action: :edit)
    end
  end

  # DELETE /tickets/1
  # DELETE /tickets/1.json
  def destroy
    @ticket.destroy
    redirect_to(tickets_url, notice: 'Ticket was successfully destroyed.')
  end
  
  def search
    searched_tickets = nil
    case params[:tab_id]
    when "keyword"
      searched_tickets = Ticket.get_tickets(params[:target])
    when "tag"
      searched_tickets = Tag.get_tickets(params[:target], params[:method]).uniq
    end

    @searched_tickets = Kaminari.paginate_array(searched_tickets).page(params[:page]).per(Ticket::PagenatePer)

    respond_to do |format|
      format.html
      format.js
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  private
  def set_ticket
    @ticket = Ticket.find(params[:id])
  end
  
  # set user id to @id.
  private
  def set_user_id
    @id = User.get_user_id(session[:uid])
  end
  
  # set user to @user.
  private
  def set_user
    @user = User.find_by(uid: session[:uid])
  end
  
  # Never trust parameters from the scary internet, only allow the white list through.
  private
  def ticket_params
    params.require(:ticket).permit(:event_name, :datetime, :place, :price, :note, :user_id)
  end

end
