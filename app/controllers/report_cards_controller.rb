class ReportCardsController < ApplicationController
  before_filter :authenticate
  
  def index
  end
  
  def show
    name = params[:id]
    @report_card = ReportCard.find_card_named(name)
    if !@report_card || !current_user.student_access_for?(@report_card.student_id)
      flash[:failure] = "Sorry, you don't have access to that report card."
      redirect_to account_url
    else
      respond_to do |format| 
        format.html { render :text => @report_card.encoded_content[0, 20] }
        format.pdf do
          response.headers['Content-type'] = 'application/pdf'
          response.headers["Content-Disposition"] = "inline; filename=#{name}.pdf"
          render :text => @report_card.body
        end
      end
    end
  end
end
