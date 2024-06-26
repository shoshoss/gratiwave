# app/jobs/post_creation_job.rb
class PostCreationJob < ApplicationJob
  queue_as :default

  # 投稿を非同期で作成するジョブ
  def perform(post_id, recipient_ids, privacy)
    post = Post.find(post_id)

    recipient_ids.each do |recipient_id|
      post.post_users.create(user_id: recipient_id, role: 'direct_recipient', approved: true)
    end

    # 投稿のプライバシー設定が 'selected_users' の場合
    NotificationJob.perform_later('direct', post.id) if privacy == 'selected_users'
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Failed to find post: #{e.message}"
  end
end
