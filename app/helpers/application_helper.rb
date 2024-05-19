# frozen_string_literal: true

module ApplicationHelper
  include Pagy::Frontend

  def page_title(title = '')
    base_title = 'ConGraWa APP'
    title.present? ? "#{title} | #{base_title}" : base_title
  end

  def flash_class(type)
    case type.to_sym
    when :notice
      'alert alert-info'       # 青色の背景
    when :success
      'alert alert-success'    # 緑色の背景
    when :error
      'alert alert-error'      # 赤色の背景
    when :alert, :danger
      'alert alert-warning'    # 黄色の背景
    else
      'alert alert-default'    # デフォルト（グレー）の背景
    end
  end

  # 投稿一覧
  # \nだけ置換
  def nl2br(input)
    (sanitize input).gsub("\n", '<br>')
  end

  # プロフィール画面 paramsの値に応じてアクティブクラスを適用
  
  def active_tab_class(*categories)
    initial_category = current_user == @user ? 'all_my_posts' : 'my_posts_open'
    active_category = params[:category] || initial_category
    
    if categories.include?(active_category)
      case active_category
      when 'all_my_posts', 'only_me', 'my_posts_open'
        'c-tab-active c-tab-active-all-my-posts'
      when 'all_likes_chance', 'my_likes_chance', 'public_likes_chance'
        'c-tab-active c-tab-active-all-likes-chance'
      when 'bookmarked'
        'c-tab-active c-tab-active-bookmarked'
      when 'liked'
        'c-tab-active c-tab-active-liked'
      else
        'c-tab-active'
      end
    else
      ''
    end
  end
  

  # 投稿画面 paramsの値に応じてアクティブクラスを適用
  def active_bottom(privacy_value)
    params[:privacy] == privacy_value ? 'c-bottom-active' : ''
  end
end
