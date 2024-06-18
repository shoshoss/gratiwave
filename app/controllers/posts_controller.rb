# app/controllers/posts_controller.rb
class PostsController < ApplicationController
  include ActionView::RecordIdentifier

  skip_before_action :require_login, only: %i[index show]
  before_action :set_post, only: %i[show edit update destroy]
  before_action :set_current_user_post, only: %i[edit update destroy]
  before_action :set_followings_by_post_count, only: %i[new edit create update]
  before_action :authorize_view!, only: [:show]

  def index
    @show_reply_line = false
    @pagy, @posts = pagy_countless(fetch_posts, items: 10)
  end

  def show
    @show_reply_line = true
    @notifications = current_user&.received_notifications&.unread
    @reply = Post.new
    @pagy, @replies = pagy_countless(@post.replies.includes(:user).order(created_at: :asc), items: 15)
    @parent_posts = @post.ancestors
  end

  def new
    @post = Post.new
    params[:privacy] ||= @post.privacy
  end

  def edit; end

  def create
    @post = current_user.posts.build(post_params.except(:recipient_ids, :audio))
    
    if @post.save
      if post_params[:audio].present?
        UploadAudioJob.perform_later(@post.id, post_params[:audio])
      end
      PostCreationJob.perform_later(@post.id, post_params[:recipient_ids]) # 投稿保存後の関連処理を非同期で実行
      flash[:notice] = t('defaults.flash_message.created', item: Post.model_name.human, default: '投稿が作成されました。')
      render turbo_stream: [
        turbo_stream.remove('post_modal'),
        turbo_stream.prepend('post-list', partial: 'posts/post', locals: { post: @post }),
        turbo_stream.replace('flash', partial: 'shared/flash_message', locals: { flash: })
      ]
    else
      flash.now[:danger] = t('defaults.flash_message.not_created', item: Post.model_name.human, default: '投稿の作成に失敗しました。')
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @post.update(post_params.except(:recipient_ids, :audio))
      if post_params[:audio].present?
        UploadAudioJob.perform_later(@post.id, post_params[:audio])
      end
      PostUsersCreationJob.perform_later(@post.id, post_params[:recipient_ids]) if post_params[:recipient_ids].present?
      flash[:notice] = t('defaults.flash_message.updated', item: Post.model_name.human, default: '投稿が更新されました。')
      redirect_to user_post_path(current_user.username_slug, @post)
    else
      flash.now[:danger] = t('defaults.flash_message.not_updated', item: Post.model_name.human, default: '投稿の更新に失敗しました。')
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    flash.now[:notice] = t('defaults.flash_message.deleted', item: Post.model_name.human, default: '投稿が削除されました。')
    respond_to do |format|
      format.html { redirect_to posts_path, status: :see_other }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@post)),
          turbo_stream.update('flash', partial: 'shared/flash_message', locals: { flash: })
        ]
      end
    end
  end

  private

  # 特定の投稿をセットする
  def set_post
    @post = Post.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'この投稿は存在しません。'
  end

  # ログインユーザーの投稿をセットする
  def set_current_user_post
    @post = current_user.posts.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: 'この投稿は存在しません。'
  end

  # 投稿のパラメータを許可する
  def post_params
    params.require(:post).permit(:user_id, :body, :audio, :duration, :privacy, :post_reply_id, recipient_ids: [])
  end

  # フォローしているユーザーを投稿数でソートする
  def set_followings_by_post_count
    @sorted_followings = current_user.following_ordered_by_sent_posts
  end

  # 投稿一覧を取得するメソッド
  def fetch_posts
    latest_reposts = Repost.select('DISTINCT ON (post_id) *')
                           .order('post_id, created_at DESC')

    Post.open
        .select('posts.*, COALESCE(latest_reposts.created_at, posts.created_at) AS reposted_at')
        .joins("LEFT JOIN (#{latest_reposts.to_sql}) AS latest_reposts ON latest_reposts.post_id = posts.id")
        .includes(:user, :reposts)
        .order(Arel.sql('reposted_at DESC'))
  end

  # 投稿の表示権限を確認
  def authorize_view!
    return if @post.visible_to?(current_user)

    redirect_to root_path, alert: 'この投稿を見る権限がありません。'
  end
end
