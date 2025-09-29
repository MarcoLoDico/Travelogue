# OpenID Connect Configuration
Rails.application.config.oidc = {
  # OIDC Provider Configuration
  issuer: ENV.fetch("OIDC_ISSUER", "http://localhost:3000"),
  client_id: ENV.fetch("OIDC_CLIENT_ID", "travelogue"),
  client_secret: ENV.fetch("OIDC_CLIENT_SECRET", "your-secret-key"),

  # JWT Configuration
  jwt_secret: ENV.fetch("JWT_SECRET", Rails.application.secret_key_base),
  jwt_algorithm: "HS256",
  jwt_expiration: 1.hour,
  jwt_refresh_expiration: 7.days,

  # OIDC Endpoints
  authorization_endpoint: "/oauth/authorize",
  token_endpoint: "/oauth/token",
  userinfo_endpoint: "/oauth/userinfo",
  jwks_uri: "/oauth/jwks",

  # Scopes
  default_scopes: "openid profile email",

  # PKCE Configuration
  use_pkce: true,

  # Security
  state_parameter: true,
  nonce_parameter: true
}

# JWT Configuration
Rails.application.config.jwt = {
  secret: Rails.application.config.oidc[:jwt_secret],
  algorithm: Rails.application.config.oidc[:jwt_algorithm],
  expiration: Rails.application.config.oidc[:jwt_expiration],
  refresh_expiration: Rails.application.config.oidc[:jwt_refresh_expiration]
}
