class StaticPagesController < ApplicationController
  def home
  end

  def search
    @search = Search.new
  end
end
