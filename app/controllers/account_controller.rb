class AccountController < ApplicationController
  before_filter :authenticate
  
  def show
  end
end
