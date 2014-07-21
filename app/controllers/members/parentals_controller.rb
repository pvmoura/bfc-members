class Members::ParentalsController < ApplicationController
  before_action :set_member
  before_action :set_parental, only: [:show, :edit, :update, :destroy]
  before_action :set_selects, only: [:new, :edit, :create, :update]

  # GET /members/:member_id/parentals
  # GET /members/:member_id/parentals.json
  # GET /members/:member_id/parentals.csv
  def index
    @parentals = @member.parentals.include_parents.where(params[:search])
    @receiver = Receiver.new
    respond_with(@parentals)
  end

  # GET /members/:member_id/parentals/1
  # GET /members/:member_id/parentals/1.json
  # GET /members/:member_id/parentals/1.csv
  def show
    respond_with(@parental)
  end

  # GET /members/:member_id/parentals/new
  def new
    @receiver = Receiver.new
    @parental = @member.parentals.new
  end

  # GET /members/:member_id/parentals/1/edit
  def edit
  end

  # POST /members/:member_id/parentals
  # POST /members/:member_id/parentals.json
  def create
    @parental = @member.parentals.new(parental_params)

    respond_to do |format|
      if @parental.save
        format.html { redirect_to member_parental_path(@member, @parental), notice: 'Parental Leave was successfully created.' }
        format.json { render :show, status: :created, location: @parental }
      else
        format.html { render :new }
        format.json { render json: @parental.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /members/:member_id/parentals/1
  # PATCH/PUT /members/:member_id/parentals/1.json
  def update
    respond_to do |format|
      if @parental.update(parental_params)
        format.html { redirect_to member_parental_path(@member, @parental), notice: 'Parental Leave was successfully updated.' }
        format.json { render :show, status: :ok, location: @parental }
      else
        format.html { render :edit }
        format.json { render json: @parental.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /members/:member_id/parentals/1
  # DELETE /members/:member_id/parentals/1.json
  def destroy
    @parental.destroy
    respond_to do |format|
      format.html { redirect_to member_furloughs_url(@member), notice: 'Parental Leave was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_member
      @member = Member.find(params[:member_id])
    end

    def set_parental
      @parental = Parental.include_parents.find(params[:id])
      @receiver = @parental.receiver
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def parental_params
      params.require(:parental).permit(:member_id, :receiver_id, :type, :start, :finish)
    end

    def set_selects
      @receivers = Receiver.form_select.collect{|r| [r.full_name, r.id]}
    end
end