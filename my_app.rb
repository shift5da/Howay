require 'sinatra'
require "sinatra/reloader" if development?
require "sinatra/activerecord"
require "sinatra/json"
require 'will_paginate'
require 'will_paginate/active_record'
require "will_paginate-bootstrap"
require 'securerandom'


# 创建一个存放静态文件的目录，主要存放css、js、font、image等文件
set :public_folder, File.dirname(__FILE__) + '/static'
set :root, File.dirname(__FILE__)

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

class Image < ActiveRecord::Base
end

class Attachment < ActiveRecord::Base
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
  @tag_groups = TagGroup.order('id desc').paginate(:page => params[:page])
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
  @tags = Tag.order('id desc').paginate(:page => params[:page])
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
  @articles = Article.order('updated_at desc').paginate(:page => params[:page])
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
  article.abstract = params[:abstract]
  article.content = params[:content]
  article.tags = Tag.find(params[:tags]) if params.include? :tags
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
  article.abstract = params[:abstract]
  article.content = params[:content]
  article.tags = Tag.find(params[:tags]) if params.include? :tags
  article.save
  redirect '/setting/articles'
end

get '/setting/articles/:article_id/destroy' do
  @article = Article.find params[:article_id]
  @article.destroy
  redirect '/setting/articles'
end


get '/setting/images' do
  session[:current_setting_menu] = 'image'
  @images = Image.order('created_at desc').paginate(:page => params[:page])
  erb :'setting/image/index'
end

get '/setting/images/:image_id/delete' do

  image = Image.find(params[:image_id])

  unless image.nil?
    File.delete "static/#{image.url}" if File.exist? "static/#{image.url}"
    image.destroy
  end
  redirect '/setting/images'
end

post '/setting/images' do
  logger.debug request
  if params.include? :avatar
    params[:avatar].each do |avatar|

      filename = avatar[:filename]
      tempfile = avatar[:tempfile]
      logger.debug "filename = #{filename}"
      extension_name = filename[filename.rindex('.')..filename.length]
      Dir.mkdir "static/upload_images" unless Dir.exist? "static/upload_images"
      my_image = Image.new
      # logger.debug "======" + image.methods.to_s
      my_image.ori_filename = filename
      my_image.name = SecureRandom.uuid + extension_name
      my_image.url = "upload_images/" + my_image.name
      my_image.content_type = avatar[:type]
      my_image.save
      File.open("static/" + my_image.url, 'wb') {|f| f.write tempfile.read }
    end
  end
  redirect '/setting/images'
end


get '/setting/attachments' do
  session[:current_setting_menu] = 'attachment'
  @attachments = Attachment.order('created_at desc').paginate(:page => params[:page])
  erb :'setting/attachment/index'
end

get '/setting/attachments/:attachment_id/delete' do

  attachment = Attachment.find(params[:attachment_id])

  unless attachment.nil?
    File.delete "static/#{attachment.url}" if File.exist? "static/#{attachment.url}"
    attachment.destroy
  end
  redirect '/setting/attachments'
end

post '/setting/attachments' do
  logger.debug request
  if params.include? :avatar
    params[:avatar].each do |avatar|

      filename = avatar[:filename]
      tempfile = avatar[:tempfile]
      extension_name = filename[filename.rindex('.')..filename.length]
      Dir.mkdir "static/upload_attachments" unless Dir.exist? "static/upload_attachments"
      my_attachment = Attachment.new
      # logger.debug "======" + image.methods.to_s
      my_attachment.ori_filename = filename
      my_attachment.name = SecureRandom.uuid + extension_name
      my_attachment.url = "upload_attachments/" + my_attachment.name
      my_attachment.content_type = avatar[:type]
      my_attachment.save
      File.open("static/" + my_attachment.url, 'wb') {|f| f.write tempfile.read }
    end
  end
  redirect '/setting/attachments'
end
