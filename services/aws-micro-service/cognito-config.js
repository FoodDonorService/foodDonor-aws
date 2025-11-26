const requireEnv = (name, options = {}) => {
  const value = process.env[name];
  if (!value && !options.optional) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
};

const cognitoAuthConfig = {
  authority: requireEnv("COGNITO_AUTHORITY_URL"),
  client_id: requireEnv("COGNITO_APP_CLIENT_ID"),
  redirect_uri: requireEnv("COGNITO_REDIRECT_URI"),
  response_type: requireEnv("COGNITO_RESPONSE_TYPE", { optional: true }) ?? "code",
  scope: requireEnv("COGNITO_SCOPE", { optional: true }) ?? "email openid phone",
};

export default cognitoAuthConfig;