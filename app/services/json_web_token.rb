class JsonWebToken
  SECRET_KEY = Rails.application.secret_key_base
  EXPIRY = 24.hours

  def self.encode(payload, exp = EXPIRY.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::ExpiredSignature
    raise "Token has expired"
  rescue JWT::DecodeError => e
    raise "Invalid token: #{e.message}"
  end
end
