require 'sinatra'
require "sinatra/reloader" if development?
require "sinatra/activerecord"
require "sinatra/json"
require 'will_paginate'
require 'will_paginate/active_record'
require "will_paginate-bootstrap"


# 创建一个存放静态文件的目录，主要存放css、js、font、image等文件
set :public_folder, File.dirname(__FILE__) + '/static'

enable :sessions
set :session_secret, "My session secret"


set :database, {
  adapter:  'mysql2',
  host:     'localhost',
  username: 'root',
  password: 'root',
  database: 'howay'
}

Time.zone = "Beijing"
ActiveRecord::Base.default_timezone = :local

configure :development do
  set :logging, Logger::DEBUG
  set :show_exceptions, :after_handler
end

enable :sessions
set :session_secret, "4659b8f4a27d22f631163db88639714833c6c61b30d2da85f35667615c912b6a1d691e11f73289c9bd5afae3e6213ddcd478aa30f9f454a1dd10e95c1837ba97"

WillPaginate.per_page = 20

# -----------------------------------------------
# models
# -----------------------------------------------

class TagGroup < ActiveRecord::Base
  default_scope { order(:seq) }
  has_many :tags
end

class Tag < ActiveRecord::Base
  has_and_belongs_to_many :articles
  belongs_to :tag_group
end

class Article < ActiveRecord::Base
  has_and_belongs_to_many :tags
end


# -----------------------------------------------
# data
# -----------------------------------------------


# -----------------------------------------------
# controllers
# -----------------------------------------------

before  do
  if request.path_info.start_with? '/setting'
    redirect '/login' if session[:current_user_account].nil?
  end
  pass
end

get '/' do
  if params.include? 'tag'
    tag = Tag.find(params[:tag])
    if tag.nil?
      @articles = Article.all.order('created_at desc').paginate(:page => params[:page])
    else
      @articles = tag.articles.order('created_at desc').paginate(:page => params[:page])
    end
  else
    @articles = Article.all.order('created_at desc').paginate(:page => params[:page])
  end
  erb :'index'
end

get '/article/:article_id' do
  @article = Article.find(params[:article_id])
  erb :'article_detail'
end

get '/login' do
  erb :'login'
end

post '/login' do
  logger.debug request
  account = params[:account]
  password = params[:password]

  if account.eql? 'wuda' and password.eql? 'Wuda!1981'
    session[:current_user_account] = account
    redirect '/setting'
  else
    redirect '/login'
  end
end


###########
# setting #
###########

# setting: home page
get '/setting' do
  erb :'setting'
end


# setting: tag_group

get '/setting/tag_groups' do
  session[:current_setting_menu] = 'tag_group'
  @tag_groups = TagGroup.paginate(:page => params[:page])
  erb :'setting/tag_group/index'
end

get '/setting/tag_groups/new' do
  erb :'setting/tag_group/new'
end

post '/setting/tag_groups/new' do
  logger.debug request
  tg = TagGroup.new
  tg.name = params[:name]
  tg.seq = params[:seq]
  tg.save
  redirect '/setting/tag_groups'
end

get '/setting/tag_groups/:tg_id/edit' do
  @tag_group = TagGroup.find params[:tg_id]
  erb :'setting/tag_group/edit'
end

post '/setting/tag_groups/:tg_id/edit' do
  logger.debug request
  tg = TagGroup.find params[:tg_id]
  tg.name = params[:name]
  tg.seq = params[:seq]
  tg.save
  redirect '/setting/tag_groups'
end

get '/setting/tag_groups/:tg_id/destroy' do
  @tag_group = TagGroup.find params[:tg_id]
  @tag_group.destroy
  redirect '/setting/tag_groups'
end


# setting: tag
get '/setting/tags' do
  session[:current_setting_menu] = 'tag'
  @tags = Tag.paginate(:page => params[:page])
  erb :'setting/tag/index'
end

get '/setting/tags/new' do
  @tag_groups = TagGroup.all
  erb :'setting/tag/new'
end

post '/setting/tags/new' do
  logger.debug request
  tag = Tag.new
  tag.name = params[:tagName]
  tag.tag_group = TagGroup.find params[:tagGroupID]
  tag.save
  redirect '/setting/tags'
end

get '/setting/tags/:tag_id/edit' do
  @tag_groups = TagGroup.all
  @tag = Tag.find params[:tag_id]
  erb :'setting/tag/edit'
end

post '/setting/tags/:tag_id/edit' do
  logger.debug request
  tag = Tag.find params[:tag_id]
  tag.name = params[:tagName]
  tag.tag_group = TagGroup.find params[:tagGroupID]
  tag.save
  redirect '/setting/tags'
end

get '/setting/tags/:tag_id/destroy' do
  @tag = Tag.find params[:tag_id]
  @tag.destroy
  redirect '/setting/tags'
end

# setting: article
get '/setting/articles' do
  session[:current_setting_menu] = 'article'
  @articles = Article.paginate(:page => params[:page])
  erb :'setting/article/index'
end

get '/setting/articles/new' do
  @tag_groups = TagGroup.all
  erb :'setting/article/new'
end

post '/setting/articles/new' do
  logger.debug request
  article = Article.new
  article.title = params[:title]
  article.abstract = params[:title]
  article.content = params[:content]
  article.tags = Tag.find(params[:tags])
  article.save
  redirect '/setting/articles'
end

get '/setting/articles/:article_id/edit' do
  @tag_groups = TagGroup.all
  @article = Article.find params[:article_id]
  erb :'setting/article/edit'
end

post '/setting/articles/:article_id/edit' do
  logger.debug request
  article = Article.find(params[:article_id])
  article.title = params[:title]
  article.abstract = params[:title]
  article.content = params[:content]
  article.tags = Tag.find(params[:tags])
  article.save
  redirect '/setting/articles'
end

get '/setting/articles/:article_id/destroy' do
  @article = Article.find params[:article_id]
  @article.destroy
  redirect '/setting/articles'
end
