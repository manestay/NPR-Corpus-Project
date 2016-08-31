class StaticPagesController < ApplicationController
  def home
  end

  def search
    @title = 'test'
    @search = Search.new
  end
end
