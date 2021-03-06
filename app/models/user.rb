class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  
  has_many :posts
  has_many :friendships
  has_many :friends, through: :friendships, class_name: "User"
  has_many :postlikes
  
  validates :first_name, presence: :true
  validates :last_name, presence: :true
  validates :birth_date, presence: :true
  
  
   has_attached_file :avatar, styles: { medium: "300x300>", thumb: "100x100>", large: "650x650>" }, 
   #:default_url => ActionController::Base.helpers.asset_path('missing.png')
   
    #:s3_host_name   => "s3-eu-west-1.amazonaws.com"  ,
   :default_url => ":style/missing.png"
  validates_attachment :avatar,
    #:presence => true,
    :size => { :in => 0..10.megabytes },
    :content_type => { :content_type => /^image\/(jpeg|png|gif|tiff)$/ }
    
    has_attached_file :cover, styles: { medium: "850x315>"}, 
    :default_url => ":style/missing-cover.png"
    
    
  validates_attachment :cover,
    #:presence => true,
    :size => { :in => 0..10.megabytes },
    :content_type => { :content_type => /^image\/(jpeg|png|gif|tiff)$/ }
    
    crop_attached_file :avatar
  
  self.per_page = 10
    
  def full_name
    "#{first_name} #{last_name}"
  end
  
  def self.search_by_name(name)
    if Rails.env.production?  
     where('first_name ILIKE ? or last_name ILIKE ?',
      "%#{name}%", "%#{name}%").order(:first_name)
    else
      where('first_name LIKE ? or last_name LIKE ?',
      "%#{name}%", "%#{name}%").order(:first_name)
    end
  end
  
  def follows_or_same?(new_friend)
    friendships.map(&:friend).include?(new_friend) || self == new_friend
  end
  
  def not_follows(new_friend)
    !friendships.map(&:friend).include?(new_friend)
  end
  
  def current_friendship(friend)
    friendships.where(friend: friend).first
  end
  
  def posts_by_profile
    posts = Post.where(profile_posted: self)
    return posts
  end

  def followed_feed
    friends = friendships.where(user: self)
    followed = []
    feed = []
    friends.each do |f|
      followed.push(User.find(f.friend_id))
    end
    followed.push(self)
    followed.each do |fol|
      feed.push(fol.posts_by_profile).flatten!
    end
    feed.sort! { |x,y| y.created_at <=> x.created_at }
    return feed
  end
  
  def followers
    followers = []
    Friendship.where(friend: self).each do |follower|
      followers.push(User.find(follower.user_id))
    end
    return followers
  end
  
  def followed
    followed = []
    friendships.where(user: self).each do |follow|
      followed.push(User.find(follow.friend_id))
    end
    return followed
  end
  
  def followed_by_and_follower?(user)
    (followed.include?(user) && followers.include?(user)) || self == user
  end

  def already_likes?(pst)
    postlikes.map(&:post).include?(pst)
  end

end


