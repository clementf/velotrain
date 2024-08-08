class User < ApplicationRecord
  include Clearance::User

  enum role: {user: "user", dev: "dev"}
end
